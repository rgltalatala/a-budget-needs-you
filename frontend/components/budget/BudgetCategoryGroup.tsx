import { RefObject } from "react";
import type {
  BudgetMonth,
  Category,
  CategoryGroup,
  CategoryMonth,
  Goal,
} from "@/types/api";
import { BudgetCategoryRow } from "./BudgetCategoryRow";

interface BudgetCategoryGroupProps {
  group: CategoryGroup;
  rows: { cat: Category; cm: CategoryMonth | undefined }[];
  goals: Goal[];
  budgetMonth: BudgetMonth | null;
  creatingCategoryForGroupId: string | null;
  newCategoryName: string;
  newCategoryInputRef: RefObject<HTMLInputElement | null>;
  editingCategoryNameId: string | null;
  editingCategoryNameValue: string;
  editCategoryNameInputRef: RefObject<HTMLInputElement | null>;
  selectedCategoryId: string | null;
  onNewCategoryNameChange: (value: string) => void;
  onStartAddCategory: () => void;
  onSaveNewCategory: () => void;
  onCancelAddCategory: () => void;
  onStartEditCategoryName: (cat: Category) => void;
  onEditingCategoryNameChange: (value: string) => void;
  onSaveCategoryName: (cat: Category) => void;
  onCancelEditCategoryName: () => void;
  editingAllottedCategoryMonthId: string | null;
  allottedEditValue: string;
  onStartEditAllotted: (cm: CategoryMonth) => void;
  onAllottedEditChange: (value: string) => void;
  onSaveAllotted: (categoryMonthId: string, value: string) => void;
  onCancelEditAllotted: () => void;
  onSelectCategory: (cat: Category, cm: CategoryMonth | undefined, goal: Goal | undefined) => void;
}

export function BudgetCategoryGroup({
  group,
  rows,
  goals,
  budgetMonth,
  creatingCategoryForGroupId,
  newCategoryName,
  newCategoryInputRef,
  editingCategoryNameId,
  editingCategoryNameValue,
  editCategoryNameInputRef,
  selectedCategoryId,
  onNewCategoryNameChange,
  onStartAddCategory,
  onSaveNewCategory,
  onCancelAddCategory,
  onStartEditCategoryName,
  onEditingCategoryNameChange,
  onSaveCategoryName,
  onCancelEditCategoryName,
  editingAllottedCategoryMonthId,
  allottedEditValue,
  onStartEditAllotted,
  onAllottedEditChange,
  onSaveAllotted,
  onCancelEditAllotted,
  onSelectCategory,
}: BudgetCategoryGroupProps) {
  const isCreating = creatingCategoryForGroupId === group.id;

  return (
    <div className="border-2 border-gray-300 rounded-lg">
      <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-center group/header">
        <div className="flex items-center gap-2">
          <span className="font-medium text-gray-900">{group.name}</span>
          <button
            type="button"
            onClick={onStartAddCategory}
            className="opacity-0 group-hover/header:opacity-100 flex items-center gap-1.5 text-sm text-blue-600 hover:text-blue-800 transition-opacity"
            title="Add category"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4v16m8-8H4"
              />
            </svg>
            Add category
          </button>
        </div>
        <span className="text-sm text-gray-600">{rows.length} categories</span>
      </div>
      <div className="p-4 space-y-3">
        {isCreating && (
          <div className="grid grid-cols-4 gap-3 items-center">
            <input
              ref={newCategoryInputRef}
              type="text"
              value={newCategoryName}
              onChange={(e) => onNewCategoryNameChange(e.target.value)}
              onBlur={onSaveNewCategory}
              onKeyDown={(e) => {
                if (e.key === "Enter") onSaveNewCategory();
                else if (e.key === "Escape") onCancelAddCategory();
              }}
              placeholder="Category name"
              className="col-span-1 px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-900 placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              autoFocus
            />
            <div className="col-span-3 text-sm text-gray-500">
              Press Enter to save, Esc to cancel
            </div>
          </div>
        )}
        {rows.length === 0 && !isCreating ? (
          <p className="text-sm text-gray-600">
            Add categories to this group by clicking &quot;add category&quot;
            above.
          </p>
        ) : (
          rows.map(({ cat, cm }) => {
            const goal = goals.find((g) => g.category_id === cat.id);
            return (
              <BudgetCategoryRow
                key={cat.id}
                cat={cat}
                cm={cm}
                goal={goal}
                budgetMonth={budgetMonth}
                isEditingName={editingCategoryNameId === cat.id}
                editingNameValue={editingCategoryNameValue}
                showEditInputInRow={selectedCategoryId !== cat.id}
                editInputRef={editCategoryNameInputRef}
                onStartEditName={() => onStartEditCategoryName(cat)}
                onEditingNameChange={onEditingCategoryNameChange}
                onSaveName={() => onSaveCategoryName(cat)}
                onCancelEditName={onCancelEditCategoryName}
                isEditingAllotted={Boolean(cm && cm.id === editingAllottedCategoryMonthId)}
                allottedEditValue={allottedEditValue}
                onStartEditAllotted={cm ? () => onStartEditAllotted(cm) : undefined}
                onAllottedEditChange={onAllottedEditChange}
                onSaveAllotted={cm ? (value) => onSaveAllotted(cm.id, value) : undefined}
                onCancelEditAllotted={onCancelEditAllotted}
                onSelect={() => onSelectCategory(cat, cm, goal)}
              />
            );
          })
        )}
      </div>
    </div>
  );
}
