'use client';

import { useEffect, useState, useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { accountsApi, transactionsApi, budgetsApi, budgetMonthsApi } from '@/lib/api';
import { Card } from '@/components/ui/Card';
import { Loading } from '@/components/ui/Loading';
import { Error } from '@/components/ui/Error';
import type { Account, Transaction, Budget, BudgetMonth } from '@/types/api';
import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { TransactionRow } from '@/components/transactions/TransactionRow';
import { Skeleton, CardSkeleton, TableRowSkeleton } from '@/components/ui/Skeleton';
import { sumIncome, sumExpenses } from '@/lib/transactions';
import { getMonthBounds } from '@/lib/date';

export default function DashboardPage() {
  const { user } = useAuth();
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [recentTransactions, setRecentTransactions] = useState<Transaction[]>([]);
  const [monthTransactions, setMonthTransactions] = useState<Transaction[]>([]);
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [currentBudgetMonth, setCurrentBudgetMonth] = useState<BudgetMonth | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadData() {
      try {
        setLoading(true);
        const now = new Date();
        const { start, end } = getMonthBounds(now.getFullYear(), now.getMonth() + 1);

        const [accountsRes, transactionsRes, monthRes, budgetsRes] = await Promise.all([
          accountsApi.list({ per_page: 100 }),
          transactionsApi.list({ per_page: 5, include: 'category' }),
          transactionsApi.list({ start_date: start, end_date: end, include: 'category', per_page: 500 }),
          budgetsApi.list({ per_page: 1 }),
        ]);

        setAccounts(accountsRes.data);
        setRecentTransactions(transactionsRes.data);
        setMonthTransactions(monthRes.data);
        setBudgets(budgetsRes.data);

        const budget = budgetsRes.data[0];
        if (budget) {
          const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
          const monthsRes = await budgetMonthsApi.list({
            budget_id: budget.id,
            month: currentMonthKey,
            per_page: 1,
            include: 'summary',
          });
          const current = monthsRes.data[0] ?? null;
          setCurrentBudgetMonth(current);
        } else {
          setCurrentBudgetMonth(null);
        }
      } catch (err) {
        setError('Failed to load dashboard data');
        console.error(err);
      } finally {
        setLoading(false);
      }
    }

    loadData();
  }, []);

  const totalBalance = accounts.reduce((sum, account) => sum + account.balance, 0);
  const monthIncome = useMemo(() => sumIncome(monthTransactions), [monthTransactions]);
  const monthExpenses = useMemo(() => sumExpenses(monthTransactions), [monthTransactions]);
  const netThisMonth = monthIncome - monthExpenses;
  const toBeBudgeted = currentBudgetMonth?.summary?.available ?? null;

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <Skeleton className="h-9 w-64 mb-2" />
          <Skeleton className="h-5 w-96" />
        </div>
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
        <div className="bg-white rounded-lg shadow-md p-6 border-2 border-gray-300">
          <Skeleton className="h-6 w-48 mb-4" />
          <TableRowSkeleton cols={4} />
          <TableRowSkeleton cols={4} />
          <TableRowSkeleton cols={4} />
          <TableRowSkeleton cols={4} />
          <TableRowSkeleton cols={4} />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">
          Welcome back, {user?.name}!
        </h1>
        <p className="mt-2 text-gray-600">
          Here&apos;s an overview of your finances
        </p>
      </div>

      {error && <Error>{error}</Error>}

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <Card title="Total Balance" className="border-2 border-gray-300">
          <div className="text-3xl font-bold text-gray-900">
            ${totalBalance.toFixed(2)}
          </div>
          <p className="mt-2 text-sm text-gray-600">
            Across {accounts.length} account{accounts.length !== 1 ? 's' : ''}
          </p>
          <Link href="/dashboard/accounts" className="mt-4 inline-block">
            <Button variant="outline" size="sm">
              View Accounts
            </Button>
          </Link>
        </Card>

        <Card title="Net this month" className="border-2 border-gray-300">
          <div className={`text-2xl font-bold ${netThisMonth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {netThisMonth >= 0 ? '+' : ''}${netThisMonth.toFixed(2)}
          </div>
          <p className="mt-2 text-sm text-gray-600">
            Income ${monthIncome.toFixed(2)} − expenses ${monthExpenses.toFixed(2)}
          </p>
          <Link href="/dashboard/analytics" className="mt-4 inline-block">
            <Button variant="outline" size="sm">
              Analytics
            </Button>
          </Link>
        </Card>

        <Card title="Budget" className="border-2 border-gray-300">
          {toBeBudgeted !== null ? (
            <>
              <div className={`text-2xl font-bold ${toBeBudgeted >= 0 ? 'text-gray-900' : 'text-red-600'}`}>
                ${toBeBudgeted.toFixed(2)}
              </div>
              <p className="mt-2 text-sm text-gray-600">
                {toBeBudgeted >= 0 ? 'To be budgeted' : 'Overspent'}
              </p>
            </>
          ) : (
            <p className="text-sm text-gray-600">No budget month loaded</p>
          )}
          <Link href="/dashboard/budget" className="mt-4 inline-block">
            <Button variant="outline" size="sm">
              View Budget
            </Button>
          </Link>
        </Card>

        <Card title="Accounts" className="border-2 border-gray-300">
          <div className="text-3xl font-bold text-gray-900">
            {accounts.length}
          </div>
          <p className="mt-2 text-sm text-gray-600">Total accounts</p>
          {accounts.length > 0 && (
            <div className="mt-4 space-y-2">
              {accounts.slice(0, 3).map((account) => (
                <div key={account.id} className="flex justify-between text-sm">
                  <span className="text-gray-700">{account.name}</span>
                  <span className="font-medium text-gray-900">${account.balance.toFixed(2)}</span>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>

      <Card title="Recent Transactions" className="border-2 border-gray-300">
        {recentTransactions.length === 0 ? (
          <p className="text-gray-600">No transactions yet. Add one from the Transactions page.</p>
        ) : (
          <div>
            <div className="min-w-lg">
              <div className="grid grid-cols-[1fr_2fr_1.5fr_6rem] gap-3 py-2 px-2 border-b-2 border-gray-200 text-sm font-medium text-gray-600">
                <span>Date</span>
                <span>Payee</span>
                <span>Category</span>
                <span className="text-right">Amount</span>
              </div>
              {recentTransactions.map((transaction) => (
                <Link
                  key={transaction.id}
                  href={`/dashboard/transactions?open=${transaction.id}`}
                  className="block"
                >
                  <TransactionRow
                    transaction={transaction}
                    layout="table"
                  />
                </Link>
              ))}
            </div>
          </div>
        )}
        <Link href="/dashboard/transactions" className="mt-4 inline-block">
          <Button variant="outline" size="sm">
            View All Transactions
          </Button>
        </Link>
      </Card>
    </div>
  );
}
