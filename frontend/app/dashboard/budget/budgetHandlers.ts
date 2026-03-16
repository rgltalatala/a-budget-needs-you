import type { Dispatch, SetStateAction } from "react";
import {
  budgetsApi,
  budgetMonthsApi,
  categoriesApi,
  categoryGroupsApi,
  categoryMonthsApi,
  goalsApi,
} from "@/lib/api";
import { getAdjacentMonthKey, getMonthKey } from "@/lib/date";
import { fetchAllPages } from "@/lib/pagination";
import type {
  Budget,
  BudgetMonth,
  Category,
  CategoryGroup,
  CategoryMonth,
  Goal,
} from "@/types/api";

export type GoalType =
  | "needed_for_spending"
  | "target_savings_balance"
  | "monthly_savings_builder";

export interface SelectedCategory {
  cat: Category;
  cm: CategoryMonth | undefined;
  goal: Goal | undefined;
}

export interface BudgetHandlersContext {
  newCategoryName: string;
  setCreatingCategoryForGroupId: (id: string | null) => void;
  setNewCategoryName: (s: string) => void;
  setCategories: Dispatch<SetStateAction<Category[]>>;
  setError: (s: string | null) => void;
  budgetMonth: BudgetMonth | null;
  setAddingGroup: (b: boolean) => void;
  setCategoryGroups: Dispatch<SetStateAction<CategoryGroup[]>>;
  newGoalAmount: string;
  newGoalType: GoalType;
  setCreatingGoal: (b: boolean) => void;
  setGoals: Dispatch<SetStateAction<Goal[]>>;
  setSelectedCategory: Dispatch<SetStateAction<SelectedCategory | null>>;
  setNewGoalAmount: (s: string) => void;
  editingCategoryNameValue: string;
  setEditingCategoryNameId: (id: string | null) => void;
  setEditingCategoryNameValue: (s: string) => void;
  setUpdatingCategory: (b: boolean) => void;
  editGoalAmount: string;
  editGoalType: GoalType;
  setEditingGoalId: (id: string | null) => void;
  setEditGoalAmount: (s: string) => void;
  setUpdatingGoal: (b: boolean) => void;
  setDeletingCategory: (b: boolean) => void;
  setCategoryMonths: Dispatch<SetStateAction<CategoryMonth[]>>;
  // Load / navigation
  setLoading: (b: boolean) => void;
  setBudgets: Dispatch<SetStateAction<Budget[]>>;
  setBudgetMonth: Dispatch<SetStateAction<BudgetMonth | null>>;
  setBudgetMonthsList: Dispatch<SetStateAction<BudgetMonth[]>>;
  setLoadingMonthData: (b: boolean) => void;
  budgetMonthId: string | undefined;
  budgetMonthsByKey: Record<string, BudgetMonth>;
  loadingMonthData: boolean;
}

export function createBudgetHandlers(
  getCtx: () => BudgetHandlersContext
): {
  loadBudgetData: () => Promise<void>;
  selectBudgetMonth: (month: BudgetMonth) => Promise<void>;
  goToPrevMonth: () => void;
  goToNextMonth: () => void;
  handleStartAddCategory: (group: CategoryGroup) => void;
  handleSaveNewCategory: (group: CategoryGroup) => Promise<void>;
  handleCancelAddCategory: () => void;
  handleAddCategoryGroup: () => Promise<void>;
  handleCreateGoal: (categoryId: string) => Promise<void>;
  handleUpdateCategoryName: (cat: Category) => Promise<void>;
  handleUpdateGoal: (goal: Goal) => Promise<void>;
  handleDeleteCategory: (cat: Category) => Promise<void>;
  handleUpdateAllotted: (categoryMonthId: string, allotted: number) => Promise<void>;
} {
  const handlers = {
    async loadBudgetData() {
      const ctx = getCtx();
      try {
        ctx.setLoading(true);
        ctx.setError(null);
        const budgetsRes = await budgetsApi.list({ per_page: 10 });
        const budgetsData = budgetsRes.data;
        ctx.setBudgets(budgetsData);

        const activeBudget = budgetsData[0];
        if (!activeBudget) {
          ctx.setBudgetMonth(null);
          ctx.setCategoryGroups([]);
          ctx.setCategories([]);
          ctx.setCategoryMonths([]);
          return;
        }

        const now = new Date();
        const currentMonthKey = getMonthKey(
          `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`
        );

        let months = await fetchAllPages(
          (params) =>
            budgetMonthsApi.list({
              ...params,
              budget_id: activeBudget.id,
              include: "summary",
            }),
          { budget_id: activeBudget.id, per_page: 100, include: "summary" }
        );
        let current = months.find((m) => getMonthKey(m.month) === currentMonthKey);
        if (!current) {
          try {
            await budgetMonthsApi.transition(
              activeBudget.id,
              `${currentMonthKey}-01`
            );
            const refetchRes = await budgetMonthsApi.list({
              budget_id: activeBudget.id,
              per_page: 50,
              include: "summary",
            });
            months = refetchRes.data.sort((a, b) =>
              a.month < b.month ? 1 : -1
            );
            current = months.find((m) => getMonthKey(m.month) === currentMonthKey);
          } catch {
            // ignore transition failure
          }
        }
        ctx.setBudgetMonthsList(months);
        const selected = current || months[0] || null;
        ctx.setBudgetMonth(selected);

        const [categoriesRes, goalsRes] = await Promise.all([
          categoriesApi.list({ per_page: 200 }),
          goalsApi.list({ per_page: 200 }),
        ]);
        ctx.setCategories(categoriesRes.data);
        ctx.setGoals(goalsRes.data);

        if (!selected) {
          ctx.setCategoryGroups([]);
          ctx.setCategoryMonths([]);
          return;
        }

        const [groupsRes, catMonthsRes] = await Promise.all([
          categoryGroupsApi.list({
            budget_month_id: selected.id,
            per_page: 100,
          }),
          categoryMonthsApi.list({
            month: selected.month.slice(0, 10),
            per_page: 500,
          }),
        ]);
        ctx.setCategoryGroups(groupsRes.data);
        ctx.setCategoryMonths(catMonthsRes.data);
      } catch (err) {
        getCtx().setError("Failed to load budgets");
        console.error(err);
      } finally {
        getCtx().setLoading(false);
      }
    },

    async selectBudgetMonth(month: BudgetMonth) {
      const ctx = getCtx();
      if (month.id === ctx.budgetMonthId) return;
      ctx.setLoadingMonthData(true);
      ctx.setError(null);
      try {
        ctx.setBudgetMonth(month);
        const [groupsRes, catMonthsRes] = await Promise.all([
          categoryGroupsApi.list({
            budget_month_id: month.id,
            per_page: 100,
          }),
          categoryMonthsApi.list({
            month: month.month.slice(0, 10),
            per_page: 500,
          }),
        ]);
        ctx.setCategoryGroups(groupsRes.data);
        ctx.setCategoryMonths(catMonthsRes.data);
      } catch (err) {
        getCtx().setError("Failed to load month data");
        console.error(err);
      } finally {
        getCtx().setLoadingMonthData(false);
      }
    },

    goToPrevMonth() {
      const ctx = getCtx();
      if (!ctx.budgetMonth || ctx.loadingMonthData) return;
      const key = getAdjacentMonthKey(ctx.budgetMonth.month, -1);
      const prev = ctx.budgetMonthsByKey[key];
      if (prev) handlers.selectBudgetMonth(prev);
    },

    goToNextMonth() {
      const ctx = getCtx();
      if (!ctx.budgetMonth || ctx.loadingMonthData) return;
      const key = getAdjacentMonthKey(ctx.budgetMonth.month, 1);
      const next = ctx.budgetMonthsByKey[key];
      if (next) handlers.selectBudgetMonth(next);
    },

    handleStartAddCategory(group: CategoryGroup) {
      const ctx = getCtx();
      ctx.setCreatingCategoryForGroupId(group.id);
      ctx.setNewCategoryName("");
    },

    async handleSaveNewCategory(group: CategoryGroup) {
      const ctx = getCtx();
      const name = ctx.newCategoryName.trim();
      if (!name) {
        ctx.setCreatingCategoryForGroupId(null);
        ctx.setNewCategoryName("");
        return;
      }
      try {
        const cat = await categoriesApi.create({
          name,
          category_group_id: group.id,
        });
        ctx.setCategories((prev) => [...prev, cat]);
        ctx.setCreatingCategoryForGroupId(null);
        ctx.setNewCategoryName("");
      } catch {
        ctx.setError("Failed to create category");
      }
    },

    handleCancelAddCategory() {
      const ctx = getCtx();
      ctx.setCreatingCategoryForGroupId(null);
      ctx.setNewCategoryName("");
    },

    async handleAddCategoryGroup() {
      const ctx = getCtx();
      if (!ctx.budgetMonth) return;
      ctx.setAddingGroup(true);
      ctx.setError(null);
      try {
        const group = await categoryGroupsApi.create({
          name: "New Group",
          budget_month_id: ctx.budgetMonth.id,
        });
        ctx.setCategoryGroups((prev) => [...prev, group]);
      } catch {
        ctx.setError("Failed to create category group");
      } finally {
        ctx.setAddingGroup(false);
      }
    },

    async handleCreateGoal(categoryId: string) {
      const ctx = getCtx();
      const amount = parseFloat(ctx.newGoalAmount);
      if (!Number.isFinite(amount) || amount <= 0) return;
      ctx.setCreatingGoal(true);
      ctx.setError(null);
      try {
        const goal = await goalsApi.create({
          category_id: categoryId,
          goal_type: ctx.newGoalType,
          target_amount: amount,
        });
        ctx.setGoals((prev) => [...prev, goal]);
        ctx.setSelectedCategory((prev) => (prev ? { ...prev, goal } : null));
        ctx.setNewGoalAmount("");
      } catch {
        ctx.setError("Failed to create goal");
      } finally {
        ctx.setCreatingGoal(false);
      }
    },

    async handleUpdateCategoryName(cat: Category) {
      const ctx = getCtx();
      const name = ctx.editingCategoryNameValue.trim();
      if (!name || name === cat.name) {
        ctx.setEditingCategoryNameId(null);
        ctx.setEditingCategoryNameValue("");
        return;
      }
      ctx.setUpdatingCategory(true);
      ctx.setError(null);
      try {
        const updated = await categoriesApi.update(cat.id, { name });
        ctx.setCategories((prev) =>
          prev.map((c) => (c.id === cat.id ? updated : c))
        );
        ctx.setSelectedCategory((prev) =>
          prev && prev.cat.id === cat.id ? { ...prev, cat: updated } : prev
        );
        ctx.setEditingCategoryNameId(null);
        ctx.setEditingCategoryNameValue("");
      } catch {
        ctx.setError("Failed to update category name");
      } finally {
        ctx.setUpdatingCategory(false);
      }
    },

    async handleUpdateGoal(goal: Goal) {
      const ctx = getCtx();
      const amount = parseFloat(ctx.editGoalAmount);
      if (!Number.isFinite(amount) || amount <= 0) return;
      ctx.setUpdatingGoal(true);
      ctx.setError(null);
      try {
        const updated = await goalsApi.update(goal.id, {
          goal_type: ctx.editGoalType,
          target_amount: amount,
        });
        ctx.setGoals((prev) =>
          prev.map((g) => (g.id === goal.id ? updated : g))
        );
        ctx.setSelectedCategory((prev) =>
          prev && prev.goal?.id === goal.id ? { ...prev, goal: updated } : prev
        );
        ctx.setEditingGoalId(null);
        ctx.setEditGoalAmount("");
      } catch {
        ctx.setError("Failed to update goal");
      } finally {
        ctx.setUpdatingGoal(false);
      }
    },

    async handleDeleteCategory(cat: Category) {
      const ctx = getCtx();
      ctx.setDeletingCategory(true);
      ctx.setError(null);
      try {
        await categoriesApi.delete(cat.id);
        ctx.setCategories((prev) => prev.filter((c) => c.id !== cat.id));
        ctx.setGoals((prev) => prev.filter((g) => g.category_id !== cat.id));
        ctx.setCategoryMonths((prev) =>
          prev.filter((cm) => cm.category_id !== cat.id)
        );
        ctx.setSelectedCategory(null);
        ctx.setEditingCategoryNameId(null);
      } catch {
        ctx.setError("Failed to delete category");
      } finally {
        ctx.setDeletingCategory(false);
      }
    },

    async handleUpdateAllotted(categoryMonthId: string, allotted: number) {
      const ctx = getCtx();
      if (!ctx.budgetMonth) return;
      try {
        ctx.setError(null);
        await categoryMonthsApi.update(categoryMonthId, { allotted });
        const [catMonthsRes, updatedBudgetMonth] = await Promise.all([
          categoryMonthsApi.list({
            month: ctx.budgetMonth.month.slice(0, 10),
            per_page: 500,
          }),
          budgetMonthsApi.get(ctx.budgetMonth.id, { include: "summary" }),
        ]);
        ctx.setCategoryMonths(catMonthsRes.data);
        ctx.setBudgetMonth(updatedBudgetMonth);
        ctx.setBudgetMonthsList((prev) =>
          prev.map((m) => (m.id === updatedBudgetMonth.id ? updatedBudgetMonth : m))
        );
        ctx.setSelectedCategory((prev) =>
          prev?.cm?.id === categoryMonthId
            ? { ...prev, cm: catMonthsRes.data.find((cm) => cm.id === categoryMonthId) ?? prev.cm }
            : prev
        );
      } catch {
        ctx.setError("Failed to update allotted amount");
      }
    },
  };
  return handlers;
}
