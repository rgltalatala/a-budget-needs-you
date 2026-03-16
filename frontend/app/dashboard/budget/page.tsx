"use client";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Error } from "@/components/ui/Error";
import { Loading } from "@/components/ui/Loading";
import { BudgetMonthHeader } from "@/components/budget/BudgetMonthHeader";
import { BudgetCategoryGroup } from "@/components/budget/BudgetCategoryGroup";
import { CategorySummaryPanel } from "@/components/budget/CategorySummaryPanel";
import { formatBudgetMonthLabel } from "@/lib/date";
import type { CategoryMonth } from "@/types/api";
import { useBudgetData } from "./useBudgetData";

export default function BudgetPage() {
  const {
    budgets,
    budgetMonth,
    budgetMonthsList,
    loadingMonthData,
    selectBudgetMonth,
    goToPrevMonth,
    goToNextMonth,
    canGoToPrevMonth,
    canGoToNextMonth,
    categoryGroups,
    categories,
    categoryMonths,
    goals,
    loading,
    error,
    creatingCategoryForGroupId,
    newCategoryName,
    addingGroup,
    selectedCategory,
    newGoalAmount,
    newGoalType,
    creatingGoal,
    editingCategoryNameId,
    editingCategoryNameValue,
    editingGoalId,
    editGoalAmount,
    editGoalType,
    updatingGoal,
    deletingCategory,
    newCategoryInputRef,
    editCategoryNameInputRef,
    setNewCategoryName,
    setSelectedCategory,
    setNewGoalAmount,
    setNewGoalType,
    setEditingCategoryNameId,
    setEditingCategoryNameValue,
    setEditGoalAmount,
    setEditGoalType,
    setEditingGoalId,
    handleStartAddCategory,
    handleSaveNewCategory,
    handleCancelAddCategory,
    handleAddCategoryGroup,
    handleCreateGoal,
    handleUpdateCategoryName,
    handleUpdateGoal,
    handleDeleteCategory,
    handleUpdateAllotted,
    editingAllottedCategoryMonthId,
    setEditingAllottedCategoryMonthId,
    allottedEditValue,
    setAllottedEditValue,
  } = useBudgetData();

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
        <h1 className="text-3xl font-bold text-gray-900">Budget</h1>
        <p className="mt-2 text-gray-600">Manage your budget</p>
      </div>

      {error && <Error>{error}</Error>}

      <div className="grid grid-cols-1 gap-6">
        {budgets.length === 0 ? (
          <Card>
            <div className="text-center py-12">
              <p className="text-gray-600">No budget yet.</p>
            </div>
          </Card>
        ) : (
          <div
            className={`grid gap-6 ${selectedCategory ? "lg:grid-cols-3" : "grid-cols-1"}`}
          >
            <div
              className={selectedCategory ? "lg:col-span-2" : ""}
            >
              <Card
                title="This Month"
                className="border-2 border-gray-300"
              >
                {!budgetMonth ? (
                  <p className="text-gray-600">No budget month found yet.</p>
                ) : (
                  <div className="space-y-6">
                    {budgetMonth && (
                      <>
                        {budgetMonthsList.length >= 1 && (
                          <div className="flex items-center gap-2 flex-wrap">
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              aria-label="Previous month"
                              disabled={loadingMonthData || !canGoToPrevMonth}
                              onClick={goToPrevMonth}
                              className="shrink-0 h-9 w-9 p-0 inline-flex items-center justify-center"
                            >
                              <span className="inline-flex items-center justify-center w-full leading-none -translate-x-px">
                                ←
                              </span>
                            </Button>
                            <span
                              id="budget-month-label"
                              className="min-w-40 text-center font-medium text-gray-900"
                            >
                              {formatBudgetMonthLabel(budgetMonth.month)}
                            </span>
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              aria-label="Next month"
                              disabled={loadingMonthData || !canGoToNextMonth}
                              onClick={goToNextMonth}
                              className="shrink-0 h-9 w-9 p-0 inline-flex items-center justify-center"
                            >
                              <span className="inline-flex items-center justify-center w-full leading-none -translate-x-px">
                                →
                              </span>
                            </Button>
                            <label htmlFor="budget-month-jump" className="sr-only">
                              Jump to month
                            </label>
                            <select
                              id="budget-month-jump"
                              value={budgetMonth.id}
                              onChange={(e) => {
                                const bm = budgetMonthsList.find((m) => m.id === e.target.value);
                                if (bm) selectBudgetMonth(bm);
                              }}
                              disabled={loadingMonthData}
                              className="ml-2 px-3 py-1.5 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            >
                              {[...budgetMonthsList]
                                .sort((a, b) => b.month.localeCompare(a.month))
                                .map((m) => (
                                  <option key={m.id} value={m.id}>
                                    {formatBudgetMonthLabel(m.month)}
                                  </option>
                                ))}
                            </select>
                          </div>
                        )}
                        <BudgetMonthHeader budgetMonth={budgetMonth} />
                      </>
                    )}

                    {categoryGroups.length === 0 ? (
                      <p className="text-gray-600">
                        No category groups yet for this month.
                      </p>
                    ) : (
                      <div className="space-y-6">
                        <div>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={handleAddCategoryGroup}
                            disabled={addingGroup || !budgetMonth}
                          >
                            + Add category group
                          </Button>
                        </div>
                        {categoryGroups.map((group) => {
                          // Derive categories in this group from categoryMonths for this budget month
                          // (Category.category_group_id is global; category_months carry structure per month)
                          const groupCategories = categoryMonths
                            .filter((cm) => cm.category_group_id === group.id)
                            .map((cm) =>
                              categories.find((c) => c.id === cm.category_id),
                            )
                            .filter(
                              (c): c is NonNullable<typeof c> => c != null,
                            );
                          const rows = groupCategories.map((cat) => {
                            const cm = categoryMonths.find(
                              (m) => m.category_id === cat.id,
                            );
                            return { cat, cm };
                          });
                          return (
                            <BudgetCategoryGroup
                              key={group.id}
                              group={group}
                              rows={rows}
                              goals={goals}
                              budgetMonth={budgetMonth}
                              creatingCategoryForGroupId={
                                creatingCategoryForGroupId
                              }
                              newCategoryName={newCategoryName}
                              newCategoryInputRef={newCategoryInputRef}
                              editingCategoryNameId={editingCategoryNameId}
                              editingCategoryNameValue={
                                editingCategoryNameValue
                              }
                              editCategoryNameInputRef={
                                editCategoryNameInputRef
                              }
                              selectedCategoryId={selectedCategory?.cat.id ?? null}
                              onNewCategoryNameChange={setNewCategoryName}
                              onStartAddCategory={() =>
                                handleStartAddCategory(group)
                              }
                              onSaveNewCategory={() =>
                                handleSaveNewCategory(group)
                              }
                              onCancelAddCategory={handleCancelAddCategory}
                              onStartEditCategoryName={(cat) => {
                                setEditingCategoryNameId(cat.id);
                                setEditingCategoryNameValue(cat.name);
                              }}
                              onEditingCategoryNameChange={
                                setEditingCategoryNameValue
                              }
                              onSaveCategoryName={handleUpdateCategoryName}
                              onCancelEditCategoryName={() => {
                                setEditingCategoryNameId(null);
                                setEditingCategoryNameValue("");
                              }}
                              editingAllottedCategoryMonthId={
                                editingAllottedCategoryMonthId
                              }
                              allottedEditValue={allottedEditValue}
                              onStartEditAllotted={(cm: CategoryMonth) => {
                                setEditingAllottedCategoryMonthId(cm.id);
                                setAllottedEditValue(
                                  String(cm.allotted ?? 0)
                                );
                              }}
                              onAllottedEditChange={setAllottedEditValue}
                              onSaveAllotted={(categoryMonthId: string, value: string) => {
                                const trimmed = value.trim();
                                const n = trimmed === "" ? 0 : parseFloat(value);
                                if (
                                  !Number.isNaN(n) &&
                                  n >= 0 &&
                                  categoryMonthId
                                ) {
                                  handleUpdateAllotted(categoryMonthId, n);
                                }
                                setEditingAllottedCategoryMonthId(null);
                                setAllottedEditValue("");
                              }}
                              onCancelEditAllotted={() => {
                                setEditingAllottedCategoryMonthId(null);
                                setAllottedEditValue("");
                              }}
                              onSelectCategory={(cat, cm, goal) =>
                                setSelectedCategory({ cat, cm, goal })
                              }
                            />
                          );
                        })}
                      </div>
                    )}
                  </div>
                )}
              </Card>
            </div>

            {selectedCategory && (
              <CategorySummaryPanel
                selectedCategory={selectedCategory}
                budgetMonth={budgetMonth}
                editingCategoryNameId={editingCategoryNameId}
                editingCategoryNameValue={editingCategoryNameValue}
                editCategoryNameInputRef={editCategoryNameInputRef}
                editingGoalId={editingGoalId}
                editGoalAmount={editGoalAmount}
                editGoalType={editGoalType}
                newGoalAmount={newGoalAmount}
                newGoalType={newGoalType}
                creatingGoal={creatingGoal}
                updatingGoal={updatingGoal}
                deletingCategory={deletingCategory}
                onClose={() => setSelectedCategory(null)}
                onStartEditName={() => {
                  setEditingCategoryNameId(selectedCategory.cat.id);
                  setEditingCategoryNameValue(selectedCategory.cat.name);
                }}
                onEditingNameChange={setEditingCategoryNameValue}
                onSaveName={() =>
                  handleUpdateCategoryName(selectedCategory.cat)
                }
                onCancelEditName={() => {
                  setEditingCategoryNameId(null);
                  setEditingCategoryNameValue("");
                }}
                onStartEditGoal={() => {
                  if (selectedCategory.goal) {
                    setEditingGoalId(selectedCategory.goal.id);
                    setEditGoalType(
                      selectedCategory.goal.goal_type as typeof editGoalType,
                    );
                    setEditGoalAmount(
                      String(selectedCategory.goal.target_amount ?? ""),
                    );
                  }
                }}
                onEditGoalAmountChange={setEditGoalAmount}
                onEditGoalTypeChange={setEditGoalType}
                onSaveGoal={() =>
                  selectedCategory.goal &&
                  handleUpdateGoal(selectedCategory.goal)
                }
                onCancelEditGoal={() => {
                  setEditingGoalId(null);
                  setEditGoalAmount("");
                }}
                onNewGoalAmountChange={setNewGoalAmount}
                onNewGoalTypeChange={setNewGoalType}
                onCreateGoal={() =>
                  handleCreateGoal(selectedCategory.cat.id)
                }
                onDeleteCategory={() =>
                  handleDeleteCategory(selectedCategory.cat)
                }
              />
            )}
          </div>
        )}
      </div>
    </div>
  );
}
