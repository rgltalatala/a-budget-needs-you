import { RefObject, useEffect, useRef } from "react";
import { ProgressBar } from "@/components/ui/ProgressBar";
import type {
  BudgetMonth,
  Category,
  CategoryMonth,
  Goal,
} from "@/types/api";

interface BudgetCategoryRowProps {
  cat: Category;
  cm: CategoryMonth | undefined;
  goal: Goal | undefined;
  budgetMonth: BudgetMonth | null;
  isEditingName: boolean;
  editingNameValue: string;
  showEditInputInRow: boolean;
  editInputRef: RefObject<HTMLInputElement | null>;
  onStartEditName: () => void;
  onEditingNameChange: (value: string) => void;
  onSaveName: () => void;
  onCancelEditName: () => void;
  isEditingAllotted: boolean;
  allottedEditValue: string;
  onStartEditAllotted?: () => void;
  onAllottedEditChange: (value: string) => void;
  onSaveAllotted?: (value: string) => void;
  onCancelEditAllotted: () => void;
  onSelect: () => void;
}

export function BudgetCategoryRow({
  cat,
  cm,
  goal,
  budgetMonth,
  isEditingName,
  editingNameValue,
  showEditInputInRow,
  editInputRef,
  onStartEditName,
  onEditingNameChange,
  onSaveName,
  onCancelEditName,
  isEditingAllotted,
  allottedEditValue,
  onStartEditAllotted,
  onAllottedEditChange,
  onSaveAllotted,
  onCancelEditAllotted,
  onSelect,
}: BudgetCategoryRowProps) {
  const allottedInputRef = useRef<HTMLInputElement>(null);
  const allotted = cm?.allotted ?? 0;
  const spent = cm?.spent || 0;
  const isIncomeCategory = cat.name.toLowerCase() === "income";
  const incomeTotal = budgetMonth?.summary?.income ?? 0;

  useEffect(() => {
    if (isEditingAllotted) allottedInputRef.current?.focus();
  }, [isEditingAllotted]);

  return (
    <div
      className="space-y-2 cursor-pointer rounded-lg p-2 -m-2 hover:bg-gray-50 transition-colors"
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onSelect();
        }
      }}
    >
      <div className="grid grid-cols-4 gap-3 items-center text-sm">
        <div
          className="col-span-1 font-medium text-gray-900"
          onClick={(e) => {
            e.stopPropagation();
            onStartEditName();
          }}
        >
          {isEditingName && showEditInputInRow ? (
            <input
              ref={editInputRef}
              type="text"
              value={editingNameValue}
              onChange={(e) => onEditingNameChange(e.target.value)}
              onBlur={onSaveName}
              onKeyDown={(e) => {
                if (e.key === "Enter") onSaveName();
                else if (e.key === "Escape") onCancelEditName();
              }}
              className="w-full px-2 py-1 border border-gray-300 rounded text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
              onClick={(ev) => ev.stopPropagation()}
            />
          ) : (
            <span className="hover:underline cursor-pointer">{cat.name}</span>
          )}
        </div>
        {isIncomeCategory ? (
          <>
            <div className="col-span-1 text-green-600 font-medium">
              Income: ${incomeTotal.toFixed(2)}
            </div>
            <div className="col-span-2" />
          </>
        ) : (
          <>
            <div
              className="col-span-1 text-gray-700"
              onClick={(e) => {
                e.stopPropagation();
                if (onStartEditAllotted) onStartEditAllotted();
              }}
            >
              {isEditingAllotted ? (
                <input
                  ref={allottedInputRef}
                  type="text"
                  inputMode="decimal"
                  value={allottedEditValue}
                  onChange={(e) => onAllottedEditChange(e.target.value)}
                  onBlur={() => onSaveAllotted?.(allottedEditValue)}
                  onKeyDown={(e) => {
                    e.stopPropagation();
                    if (e.key === "Enter") onSaveAllotted?.(allottedEditValue);
                    else if (e.key === "Escape") onCancelEditAllotted();
                  }}
                  className="w-full max-w-28 px-2 py-1 border border-gray-300 rounded text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  onClick={(ev) => ev.stopPropagation()}
                />
              ) : (
                <span
                  className={
                    onStartEditAllotted
                      ? "hover:underline cursor-pointer"
                      : ""
                  }
                >
                  Allotted: ${allotted.toFixed(2)}
                </span>
              )}
            </div>
            <div className="col-span-1 text-gray-700">
              Spent: ${spent.toFixed(2)}
            </div>
            <div
              className={`col-span-1 font-medium ${(cm?.balance || 0) < 0 ? "text-red-600" : "text-gray-700"}`}
            >
              Available: ${(cm?.balance || 0).toFixed(2)}
            </div>
          </>
        )}
      </div>
      {!isIncomeCategory && (
        <div className="ml-0">
          <ProgressBar
            allotted={allotted}
            spent={spent}
            goalAmount={goal?.target_amount ?? null}
          />
        </div>
      )}
    </div>
  );
}
