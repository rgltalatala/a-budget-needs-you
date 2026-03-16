import { RefObject } from "react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import type {
  BudgetMonth,
  Category,
  CategoryMonth,
  Goal,
} from "@/types/api";

export type GoalType =
  | "needed_for_spending"
  | "target_savings_balance"
  | "monthly_savings_builder";

interface CategorySummaryPanelProps {
  selectedCategory: {
    cat: Category;
    cm: CategoryMonth | undefined;
    goal: Goal | undefined;
  };
  budgetMonth: BudgetMonth | null;
  editingCategoryNameId: string | null;
  editingCategoryNameValue: string;
  editCategoryNameInputRef: RefObject<HTMLInputElement | null>;
  editingGoalId: string | null;
  editGoalAmount: string;
  editGoalType: GoalType;
  newGoalAmount: string;
  newGoalType: GoalType;
  creatingGoal: boolean;
  updatingGoal: boolean;
  deletingCategory: boolean;
  onClose: () => void;
  onStartEditName: () => void;
  onEditingNameChange: (value: string) => void;
  onSaveName: () => void;
  onCancelEditName: () => void;
  onStartEditGoal: () => void;
  onEditGoalAmountChange: (value: string) => void;
  onEditGoalTypeChange: (value: GoalType) => void;
  onSaveGoal: () => void;
  onCancelEditGoal: () => void;
  onNewGoalAmountChange: (value: string) => void;
  onNewGoalTypeChange: (value: GoalType) => void;
  onCreateGoal: () => void;
  onDeleteCategory: () => void;
}

export function CategorySummaryPanel({
  selectedCategory,
  budgetMonth,
  editingCategoryNameId,
  editingCategoryNameValue,
  editCategoryNameInputRef,
  editingGoalId,
  editGoalAmount,
  editGoalType,
  newGoalAmount,
  newGoalType,
  creatingGoal,
  updatingGoal,
  deletingCategory,
  onClose,
  onStartEditName,
  onEditingNameChange,
  onSaveName,
  onCancelEditName,
  onStartEditGoal,
  onEditGoalAmountChange,
  onEditGoalTypeChange,
  onSaveGoal,
  onCancelEditGoal,
  onNewGoalAmountChange,
  onNewGoalTypeChange,
  onCreateGoal,
  onDeleteCategory,
}: CategorySummaryPanelProps) {
  const isEditingName = editingCategoryNameId === selectedCategory.cat.id;
  const isEditingGoal =
    selectedCategory.goal && editingGoalId === selectedCategory.goal?.id;
  const isIncomeCategory =
    selectedCategory.cat.name.toLowerCase() === "income";

  return (
    <Card className="lg:col-span-1 border-2 border-gray-300">
      <div className="flex justify-between items-center mb-4">
        {isEditingName ? (
          <input
            ref={editCategoryNameInputRef}
            type="text"
            value={editingCategoryNameValue}
            onChange={(e) => onEditingNameChange(e.target.value)}
            onBlur={onSaveName}
            onKeyDown={(e) => {
              if (e.key === "Enter") onSaveName();
              else if (e.key === "Escape") onCancelEditName();
            }}
            className="flex-1 px-2 py-1 border border-gray-300 rounded text-lg font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        ) : (
          <h3
            className="text-lg font-semibold text-gray-900 cursor-pointer hover:underline"
            onClick={onStartEditName}
          >
            {selectedCategory.cat.name}
          </h3>
        )}
        <button
          type="button"
          onClick={onClose}
          className="text-gray-500 hover:text-gray-700 text-sm"
        >
          Close
        </button>
      </div>
      <div className="space-y-4">
        <div>
          <span className="text-sm text-gray-600">Available</span>
          <p className="text-lg font-medium text-gray-900">
            $
            {(
              selectedCategory.cm?.balance ??
              (selectedCategory.cm?.allotted ?? 0) -
                (selectedCategory.cm?.spent ?? 0)
            ).toFixed(2)}
          </p>
        </div>
        <div>
          <span className="text-sm text-gray-600">
            Cash left over from last month
          </span>
          <p className="text-lg font-medium text-gray-900">
            ${Number(budgetMonth?.summary?.carryover ?? 0).toFixed(2)}
          </p>
        </div>
        <div>
          <span className="text-sm text-gray-600">Assigned this month</span>
          <p className="text-lg font-medium text-gray-900">
            ${Number(selectedCategory.cm?.allotted ?? 0).toFixed(2)}
          </p>
        </div>
        {!isIncomeCategory &&
        (selectedCategory.goal ? (
          isEditingGoal ? (
            <div className="border border-gray-200 rounded-lg p-4 space-y-3">
              <span className="text-sm text-gray-600">Edit goal</span>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Goal type
                </label>
                <select
                  value={editGoalType}
                  onChange={(e) =>
                    onEditGoalTypeChange(e.target.value as GoalType)
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="needed_for_spending">
                    Needed for spending
                  </option>
                  <option value="target_savings_balance">
                    Target savings balance
                  </option>
                  <option value="monthly_savings_builder">
                    Monthly savings builder
                  </option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Target amount ($)
                </label>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={editGoalAmount}
                  onChange={(e) => onEditGoalAmountChange(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  onClick={onSaveGoal}
                  disabled={
                    updatingGoal ||
                    !editGoalAmount ||
                    parseFloat(editGoalAmount) <= 0
                  }
                >
                  {updatingGoal ? "Saving…" : "Save"}
                </Button>
                <Button variant="outline" size="sm" onClick={onCancelEditGoal}>
                  Cancel
                </Button>
              </div>
            </div>
          ) : (
            <div>
              <span className="text-sm text-gray-600">Goal</span>
              <div className="flex items-center gap-2">
                <p className="text-base font-medium text-gray-900">
                  {selectedCategory.goal.goal_type.replace(/_/g, " ")} — $
                  {Number(
                    selectedCategory.goal.target_amount ?? 0,
                  ).toFixed(2)}
                </p>
                <button
                  type="button"
                  onClick={onStartEditGoal}
                  className="text-sm text-blue-600 hover:text-blue-800"
                >
                  Edit
                </button>
              </div>
            </div>
          )
        ) : (
          <div className="border border-gray-200 rounded-lg p-4 space-y-3">
            <p className="text-sm text-gray-600">
              No goal set. Create a goal to track progress.
            </p>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Goal type
              </label>
              <select
                value={newGoalType}
                onChange={(e) =>
                  onNewGoalTypeChange(e.target.value as GoalType)
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="needed_for_spending">
                  Needed for spending
                </option>
                <option value="target_savings_balance">
                  Target savings balance
                </option>
                <option value="monthly_savings_builder">
                  Monthly savings builder
                </option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Target amount ($)
              </label>
              <input
                type="number"
                min="0"
                step="0.01"
                value={newGoalAmount}
                onChange={(e) => onNewGoalAmountChange(e.target.value)}
                placeholder="e.g. 500"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <Button
              size="sm"
              onClick={onCreateGoal}
              disabled={
                creatingGoal ||
                !newGoalAmount ||
                parseFloat(newGoalAmount) <= 0
              }
            >
              {creatingGoal ? "Creating…" : "Create goal"}
            </Button>
          </div>
        ))}
        <div className="pt-4 border-t border-gray-200">
          <Button
            variant="danger"
            size="sm"
            onClick={onDeleteCategory}
            disabled={deletingCategory}
          >
            {deletingCategory ? "Deleting…" : "Delete category"}
          </Button>
        </div>
      </div>
    </Card>
  );
}
