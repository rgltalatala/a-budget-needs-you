import type { Transaction } from "@/types/api";

/** Sum of positive (income) amounts. */
export function sumIncome(transactions: Transaction[]): number {
  return transactions
    .filter((t) => t.amount > 0)
    .reduce((sum, t) => sum + t.amount, 0);
}

/** Sum of absolute values of negative (expense) amounts. */
export function sumExpenses(transactions: Transaction[]): number {
  return transactions
    .filter((t) => t.amount < 0)
    .reduce((sum, t) => sum + Math.abs(t.amount), 0);
}

/** Spending grouped by category_id: { name, total }. */
export function spendingByCategory(
  transactions: Transaction[]
): Record<string, { name: string; total: number }> {
  return transactions
    .filter((t) => t.amount < 0)
    .reduce<Record<string, { name: string; total: number }>>((acc, t) => {
      const id = t.category_id;
      const name = t.category?.name ?? "Uncategorized";
      if (!acc[id]) acc[id] = { name, total: 0 };
      acc[id].total += Math.abs(t.amount);
      return acc;
    }, {});
}

export type TransactionSortField = "date" | "payee" | "category" | "amount";
export type SortDir = "asc" | "desc";

/** Sort transactions by field and direction. Returns a new array. */
export function sortTransactions(
  transactions: Transaction[],
  field: TransactionSortField,
  dir: SortDir
): Transaction[] {
  const d = dir === "asc" ? 1 : -1;
  return [...transactions].sort((a, b) => {
    switch (field) {
      case "date":
        // Compare date-only (YYYY-MM-DD) for consistent chronological order regardless of timezone/ISO format
        const aDate = a.date ? String(a.date).slice(0, 10) : "";
        const bDate = b.date ? String(b.date).slice(0, 10) : "";
        return d * aDate.localeCompare(bDate);
      case "payee":
        return d * (a.payee ?? "").localeCompare(b.payee ?? "");
      case "category":
        return d * (a.category?.name ?? "").localeCompare(b.category?.name ?? "");
      case "amount":
        return d * (a.amount - b.amount);
      default:
        return 0;
    }
  });
}
