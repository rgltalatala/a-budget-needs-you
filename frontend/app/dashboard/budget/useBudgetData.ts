import { useEffect, useMemo, useRef, useState } from "react";
import type {
  Budget,
  BudgetMonth,
  Category,
  CategoryGroup,
  CategoryMonth,
  Goal,
} from "@/types/api";
import { getAdjacentMonthKey } from "@/lib/date";
import {
  createBudgetHandlers,
  type GoalType,
  type SelectedCategory,
} from "./budgetHandlers";

export type { GoalType, SelectedCategory };

export function useBudgetData() {
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [budgetMonth, setBudgetMonth] = useState<BudgetMonth | null>(null);
  const [budgetMonthsList, setBudgetMonthsList] = useState<BudgetMonth[]>([]);
  const [loadingMonthData, setLoadingMonthData] = useState(false);
  const [categoryGroups, setCategoryGroups] = useState<CategoryGroup[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoryMonths, setCategoryMonths] = useState<CategoryMonth[]>([]);
  const [goals, setGoals] = useState<Goal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [creatingCategoryForGroupId, setCreatingCategoryForGroupId] = useState<string | null>(null);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [addingGroup, setAddingGroup] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<SelectedCategory | null>(null);

  const [creatingGoal, setCreatingGoal] = useState(false);
  const [newGoalAmount, setNewGoalAmount] = useState("");
  const [newGoalType, setNewGoalType] = useState<GoalType>("needed_for_spending");

  const [editingCategoryNameId, setEditingCategoryNameId] = useState<string | null>(null);
  const [editingCategoryNameValue, setEditingCategoryNameValue] = useState("");
  const [editingGoalId, setEditingGoalId] = useState<string | null>(null);
  const [editGoalAmount, setEditGoalAmount] = useState("");
  const [editGoalType, setEditGoalType] = useState<GoalType>("needed_for_spending");
  const [updatingCategory, setUpdatingCategory] = useState(false);
  const [updatingGoal, setUpdatingGoal] = useState(false);
  const [deletingCategory, setDeletingCategory] = useState(false);
  const [editingAllottedCategoryMonthId, setEditingAllottedCategoryMonthId] = useState<string | null>(null);
  const [allottedEditValue, setAllottedEditValue] = useState("");

  const newCategoryInputRef = useRef<HTMLInputElement>(null);
  const editCategoryNameInputRef = useRef<HTMLInputElement>(null);

  const budgetMonthsByKey = useMemo(() => {
    const map: Record<string, BudgetMonth> = {};
    for (const m of budgetMonthsList) {
      map[m.month.slice(0, 7)] = m;
    }
    return map;
  }, [budgetMonthsList]);

  const ctxRef = useRef({
    newCategoryName,
    setCreatingCategoryForGroupId,
    setNewCategoryName,
    setCategories,
    setError,
    budgetMonth,
    setAddingGroup,
    setCategoryGroups,
    newGoalAmount,
    newGoalType,
    setCreatingGoal,
    setGoals,
    setSelectedCategory,
    setNewGoalAmount,
    editingCategoryNameValue,
    setEditingCategoryNameId,
    setEditingCategoryNameValue,
    setUpdatingCategory,
    editGoalAmount,
    editGoalType,
    setEditingGoalId,
    setEditGoalAmount,
    setUpdatingGoal,
    setDeletingCategory,
    setCategoryMonths,
    setLoading,
    setBudgets,
    setBudgetMonth,
    setBudgetMonthsList,
    setLoadingMonthData,
    budgetMonthId: budgetMonth?.id,
    budgetMonthsByKey,
    loadingMonthData,
  });
  ctxRef.current = {
    newCategoryName,
    setCreatingCategoryForGroupId,
    setNewCategoryName,
    setCategories,
    setError,
    budgetMonth,
    setAddingGroup,
    setCategoryGroups,
    newGoalAmount,
    newGoalType,
    setCreatingGoal,
    setGoals,
    setSelectedCategory,
    setNewGoalAmount,
    editingCategoryNameValue,
    setEditingCategoryNameId,
    setEditingCategoryNameValue,
    setUpdatingCategory,
    editGoalAmount,
    editGoalType,
    setEditingGoalId,
    setEditGoalAmount,
    setUpdatingGoal,
    setDeletingCategory,
    setCategoryMonths,
    setLoading,
    setBudgets,
    setBudgetMonth,
    setBudgetMonthsList,
    setLoadingMonthData,
    budgetMonthId: budgetMonth?.id,
    budgetMonthsByKey,
    loadingMonthData,
  };

  const handlers = useMemo(
    () => createBudgetHandlers(() => ctxRef.current),
    []
  );

  useEffect(() => {
    handlers.loadBudgetData();
  }, [handlers]);

  const prevMonthKey = budgetMonth
    ? getAdjacentMonthKey(budgetMonth.month, -1)
    : null;
  const nextMonthKey = budgetMonth
    ? getAdjacentMonthKey(budgetMonth.month, 1)
    : null;
  const canGoToPrevMonth = Boolean(prevMonthKey && budgetMonthsByKey[prevMonthKey]);
  const canGoToNextMonth = Boolean(nextMonthKey && budgetMonthsByKey[nextMonthKey]);

  useEffect(() => {
    if (creatingCategoryForGroupId) newCategoryInputRef.current?.focus();
  }, [creatingCategoryForGroupId]);

  useEffect(() => {
    if (editingCategoryNameId) editCategoryNameInputRef.current?.focus();
  }, [editingCategoryNameId]);

  return {
    budgets,
    budgetMonth,
    budgetMonthsList,
    loadingMonthData,
    selectBudgetMonth: handlers.selectBudgetMonth,
    goToPrevMonth: handlers.goToPrevMonth,
    goToNextMonth: handlers.goToNextMonth,
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
    updatingCategory,
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
    loadBudgetData: handlers.loadBudgetData,
    handleStartAddCategory: handlers.handleStartAddCategory,
    handleSaveNewCategory: handlers.handleSaveNewCategory,
    handleCancelAddCategory: handlers.handleCancelAddCategory,
    handleAddCategoryGroup: handlers.handleAddCategoryGroup,
    handleCreateGoal: handlers.handleCreateGoal,
    handleUpdateCategoryName: handlers.handleUpdateCategoryName,
    handleUpdateGoal: handlers.handleUpdateGoal,
    handleDeleteCategory: handlers.handleDeleteCategory,
    handleUpdateAllotted: handlers.handleUpdateAllotted,
    editingAllottedCategoryMonthId,
    setEditingAllottedCategoryMonthId,
    allottedEditValue,
    setAllottedEditValue,
  };
}
