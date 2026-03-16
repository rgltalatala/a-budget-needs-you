import { formatBudgetMonthLabel } from "@/lib/date";
import type { BudgetMonth } from "@/types/api";

interface BudgetMonthHeaderProps {
  budgetMonth: BudgetMonth;
}

export function BudgetMonthHeader({ budgetMonth }: BudgetMonthHeaderProps) {
  return (
    <div className="space-y-2">
      <div className="flex justify-between text-sm">
        <span className="text-gray-900">Month</span>
        <span className="font-medium text-gray-900">
          {formatBudgetMonthLabel(budgetMonth.month)}
        </span>
      </div>
      <div className="flex justify-between text-sm">
        <span className="text-gray-900">Ready to assign</span>
        <span
          className={`font-medium ${Number(budgetMonth.available) < 0 ? "text-red-600" : "text-gray-900"}`}
        >
          ${Number(budgetMonth.available).toFixed(2)}
        </span>
      </div>
    </div>
  );
}
