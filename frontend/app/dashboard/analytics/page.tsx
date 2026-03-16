"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { transactionsApi, categoryMonthsApi, categoriesApi } from "@/lib/api";
import { Card } from "@/components/ui/Card";
import { Loading } from "@/components/ui/Loading";
import { Error } from "@/components/ui/Error";
import { Button } from "@/components/ui/Button";
import { getMonthBounds, getYearBounds } from "@/lib/date";
import { fetchAllPages } from "@/lib/pagination";
import {
  sumIncome,
  sumExpenses,
  spendingByCategory,
} from "@/lib/transactions";
import type { Transaction, CategoryMonth } from "@/types/api";

type Period = "month" | "year" | "all";

/** Group transactions by month key "YYYY-MM" and return income/expenses per month. */
function monthlyTrends(transactions: Transaction[]): { month: string; income: number; expenses: number }[] {
  const byMonth: Record<string, { income: number; expenses: number }> = {};
  for (const t of transactions) {
    const key = t.date.slice(0, 7);
    if (!byMonth[key]) byMonth[key] = { income: 0, expenses: 0 };
    if (t.amount > 0) byMonth[key].income += t.amount;
    else byMonth[key].expenses += Math.abs(t.amount);
  }
  return Object.entries(byMonth)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-12)
    .map(([month, v]) => ({ month, income: v.income, expenses: v.expenses }));
}

function downloadCSV(transactions: Transaction[], periodLabel: string) {
  const headers = ["Date", "Payee", "Category", "Amount"];
  const rows = transactions.map((t) => [
    t.date,
    t.payee ?? "",
    t.category?.name ?? "",
    t.amount.toFixed(2),
  ]);
  const csv = [headers.join(","), ...rows.map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(","))].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `transactions-${periodLabel.replace(/\s/g, "-")}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export default function AnalyticsPage() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [period, setPeriod] = useState<Period>("month");
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categoryMonths, setCategoryMonths] = useState<CategoryMonth[]>([]);
  const [categories, setCategories] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const monthStr = `${year}-${String(month).padStart(2, "0")}-01`;

  const loadTransactions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const baseParams = { include: "category" as const };

      if (period === "all") {
        const all = await fetchAllPages(
          (params) => transactionsApi.list({ ...baseParams, ...params }),
          { ...baseParams, per_page: 500 }
        );
        setTransactions(all);
      } else if (period === "year") {
        const { start, end } = getYearBounds(year);
        const all = await fetchAllPages(
          (params) =>
            transactionsApi.list({
              ...params,
              ...baseParams,
              start_date: start,
              end_date: end,
            }),
          {
            ...baseParams,
            start_date: start,
            end_date: end,
            per_page: 500,
          }
        );
        setTransactions(all);
      } else {
        const { start, end } = getMonthBounds(year, month);
        const all = await fetchAllPages(
          (params) =>
            transactionsApi.list({
              ...params,
              ...baseParams,
              start_date: start,
              end_date: end,
            }),
          {
            ...baseParams,
            start_date: start,
            end_date: end,
            per_page: 500,
          }
        );
        setTransactions(all);
      }
    } catch (err) {
      setError("Failed to load analytics data");
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [year, month, period]);

  useEffect(() => {
    loadTransactions();
  }, [loadTransactions]);

  useEffect(() => {
    if (period !== "month") return;
    let cancelled = false;
    (async () => {
      try {
        const [cmRes, catRes] = await Promise.all([
          categoryMonthsApi.list({ month: monthStr, per_page: 200 }),
          categoriesApi.list({ per_page: 200 }),
        ]);
        if (!cancelled) {
          setCategoryMonths(cmRes.data);
          setCategories(catRes.data.map((c) => ({ id: c.id, name: c.name })));
        }
      } catch {
        if (!cancelled) setCategoryMonths([]);
      }
    })();
    return () => { cancelled = true; };
  }, [period, monthStr]);

  const budgetVsActual = useMemo(() => {
    if (period !== "month" || categoryMonths.length === 0) return null;
    const spentByCat = spendingByCategory(transactions);
    const catNames: Record<string, string> = {};
    categories.forEach((c) => { catNames[c.id] = c.name; });
    // Dedupe by category_id (API can return multiple category_months per category, e.g. from multiple budget months)
    const byCategory = new Map<string, { allotted: number; name: string }>();
    for (const cm of categoryMonths) {
      const name = catNames[cm.category_id] ?? "—";
      const spent = spentByCat[cm.category_id]?.total ?? 0;
      if (cm.allotted <= 0 && spent <= 0) continue;
      if (byCategory.has(cm.category_id)) {
        const existing = byCategory.get(cm.category_id)!;
        existing.allotted += cm.allotted;
      } else {
        byCategory.set(cm.category_id, { allotted: cm.allotted, name });
      }
    }
    return Array.from(byCategory.entries())
      .map(([categoryId, { allotted, name }]) => ({
        categoryId,
        name,
        allotted,
        spent: spentByCat[categoryId]?.total ?? 0,
        diff: allotted - (spentByCat[categoryId]?.total ?? 0),
      }))
      .sort((a, b) => b.spent - a.spent);
  }, [period, categoryMonths, categories, transactions]);

  const income = sumIncome(transactions);
  const expenses = sumExpenses(transactions);
  const net = income - expenses;
  const byCategory = spendingByCategory(transactions);
  const categoryRows = Object.entries(byCategory).sort(
    (a, b) => b[1].total - a[1].total
  );
  const maxCategoryTotal = categoryRows[0]?.[1].total ?? 1;
  const trends = useMemo(() => monthlyTrends(transactions), [transactions]);
  const maxTrendValue = Math.max(1, ...trends.flatMap((t) => [t.income, t.expenses]));

  const periodLabel =
    period === "month"
      ? new Date(year, month - 1, 1).toLocaleDateString(undefined, {
          month: "long",
          year: "numeric",
        })
      : period === "year"
        ? String(year)
        : "All time";

  const years = [
    now.getFullYear(),
    now.getFullYear() - 1,
    now.getFullYear() - 2,
  ];
  const months = Array.from({ length: 12 }, (_, i) => i + 1);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loading size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <p className="mt-2 text-gray-600">
          Income, expenses, and spending by category
        </p>
      </div>

      {error && <Error>{error}</Error>}

      <div className="flex flex-wrap items-center gap-2">
        <label
          htmlFor="analytics-period"
          className="text-sm font-medium text-gray-700"
        >
          Period
        </label>
        <select
          id="analytics-period"
          value={period}
          onChange={(e) => setPeriod(e.target.value as Period)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="month">Month</option>
          <option value="year">Year</option>
          <option value="all">All time</option>
        </select>
        {period === "month" && (
          <>
            <select
              id="analytics-month"
              value={month}
              onChange={(e) => setMonth(Number(e.target.value))}
              className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {months.map((m) => (
                <option key={m} value={m}>
                  {new Date(2000, m - 1, 1).toLocaleDateString(undefined, {
                    month: "long",
                  })}
                </option>
              ))}
            </select>
            <select
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {years.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </>
        )}
        {period === "year" && (
          <select
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
            className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {years.map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <Card
          title={`Income — ${periodLabel}`}
          className="border-2 border-gray-300"
        >
          <div className="text-3xl font-bold text-green-600">
            ${income.toFixed(2)}
          </div>
        </Card>
        <Card
          title={`Expenses — ${periodLabel}`}
          className="border-2 border-gray-300"
        >
          <div className="text-3xl font-bold text-red-600">
            ${expenses.toFixed(2)}
          </div>
        </Card>
        <Card
          title={`Net — ${periodLabel}`}
          className="border-2 border-gray-300"
        >
          <div className={`text-3xl font-bold ${net >= 0 ? "text-green-600" : "text-red-600"}`}>
            {net >= 0 ? "" : "-"}${Math.abs(net).toFixed(2)}
          </div>
        </Card>
      </div>

      {trends.length > 0 && (period === "year" || period === "all") && (
        <Card title="Trends (last 12 months)" className="border-2 border-gray-300">
          <div className="space-y-3">
            {trends.map(({ month, income: inc, expenses: exp }) => (
              <div key={month} className="flex items-center gap-2">
                <span className="w-20 text-sm text-gray-600 shrink-0">
                  {new Date(month + "-01").toLocaleDateString(undefined, { month: "short", year: "2-digit" })}
                </span>
                <div className="flex-1 flex gap-1 h-6">
                  <div
                    className="bg-green-500 rounded-l min-w-[2px]"
                    style={{ width: `${(inc / maxTrendValue) * 50}%` }}
                    title={`Income: $${inc.toFixed(2)}`}
                  />
                  <div
                    className="bg-red-500 rounded-r min-w-[2px]"
                    style={{ width: `${(exp / maxTrendValue) * 50}%` }}
                    title={`Expenses: $${exp.toFixed(2)}`}
                  />
                </div>
                <span className="text-sm text-gray-700 w-24 text-right">
                  +${inc.toFixed(0)} / -${exp.toFixed(0)}
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}

      <div className="flex justify-end">
        <Button
          variant="outline"
          size="sm"
          onClick={() => downloadCSV(transactions, periodLabel)}
          disabled={transactions.length === 0}
        >
          Export CSV
        </Button>
      </div>

      {budgetVsActual && budgetVsActual.length > 0 && (
        <Card title="Budget vs actual (this month)" className="border-2 border-gray-300">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 text-left text-gray-600">
                  <th className="py-2 pr-4">Category</th>
                  <th className="py-2 pr-4 text-right">Budgeted</th>
                  <th className="py-2 pr-4 text-right">Spent</th>
                  <th className="py-2 text-right">Difference</th>
                </tr>
              </thead>
              <tbody>
                {budgetVsActual.map((row) => (
                  <tr key={row.categoryId} className="border-b border-gray-100">
                    <td className="py-2 pr-4 font-medium text-gray-900">{row.name}</td>
                    <td className="py-2 pr-4 text-right text-gray-700">${row.allotted.toFixed(2)}</td>
                    <td className="py-2 pr-4 text-right text-gray-700">${row.spent.toFixed(2)}</td>
                    <td className={`py-2 text-right font-medium ${row.diff >= 0 ? "text-green-600" : "text-red-600"}`}>
                      {row.diff >= 0 ? "+" : ""}${row.diff.toFixed(2)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <Card
        title={`Spending by category — ${periodLabel}`}
        className="border-2 border-gray-300"
      >
        {categoryRows.length === 0 ? (
          <p className="text-gray-600">No spending in this period</p>
        ) : (
          <div className="space-y-3">
            {categoryRows.map(([categoryId, { name, total }]) => (
              <div key={categoryId}>
                <div className="flex justify-between text-sm mb-1">
                  <span className="font-medium text-gray-900">{name}</span>
                  <span className="text-gray-700">${total.toFixed(2)}</span>
                </div>
                <div className="h-2 bg-gray-100 rounded overflow-hidden">
                  <div
                    className="h-full bg-blue-500 rounded"
                    style={{
                      width: `${Math.min(100, (total / maxCategoryTotal) * 100)}%`,
                    }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
