import type { Dispatch, SetStateAction } from "react";
import { transactionsApi, accountsApi, categoriesApi } from "@/lib/api";
import { getDateRangeForPreset } from "@/lib/date";
import type { Transaction, Account, Category } from "@/types/api";
import type { TransactionSortField, SortDir } from "@/lib/transactions";
import type { DateRangePreset } from "@/lib/date";

const PER_PAGE = 25;

export type { TransactionSortField, SortDir, DateRangePreset };

export interface TransactionFiltersFromUrl {
  q: string;
  sort: TransactionSortField;
  dir: SortDir;
  date: DateRangePreset;
  start: string;
  end: string;
  account_id: string;
  category_id: string;
}

export function getInitialFilters(
  searchParams: URLSearchParams | null
): TransactionFiltersFromUrl {
  return {
    q: searchParams?.get("q") ?? "",
    sort: (searchParams?.get("sort") as TransactionSortField) ?? "date",
    dir: (searchParams?.get("dir") as SortDir) ?? "desc",
    date: (searchParams?.get("date") as DateRangePreset) ?? "all",
    start: searchParams?.get("start") ?? "",
    end: searchParams?.get("end") ?? "",
    account_id: searchParams?.get("account_id") ?? "",
    category_id: searchParams?.get("category_id") ?? "",
  };
}

export interface TransactionHandlersContext {
  searchQuery: string;
  datePreset: DateRangePreset;
  customStart: string;
  customEnd: string;
  accountId: string;
  categoryId: string;
  sortField: TransactionSortField;
  sortDir: SortDir;
  selectedIds: Set<string>;
  bulkRecatCategoryId: string;
  setSearchQuery: Dispatch<SetStateAction<string>>;
  setSearchInput: Dispatch<SetStateAction<string>>;
  setPage: Dispatch<SetStateAction<number>>;
  setSortField: Dispatch<SetStateAction<TransactionSortField>>;
  setSortDir: Dispatch<SetStateAction<SortDir>>;
  setDatePreset: Dispatch<SetStateAction<DateRangePreset>>;
  setCustomStart: Dispatch<SetStateAction<string>>;
  setCustomEnd: Dispatch<SetStateAction<string>>;
  setAccountId: Dispatch<SetStateAction<string>>;
  setCategoryId: Dispatch<SetStateAction<string>>;
  setTransactions: Dispatch<SetStateAction<Transaction[]>>;
  setMeta: Dispatch<SetStateAction<{ current_page: number; per_page: number; total_pages: number; total_count: number } | null>>;
  setLoading: (b: boolean) => void;
  setLoadingMore: (b: boolean) => void;
  setError: (s: string | null) => void;
  setSelectedIds: Dispatch<SetStateAction<Set<string>>>;
  setBulkMode: Dispatch<SetStateAction<boolean>>;
  setBulkRecatOpen: Dispatch<SetStateAction<boolean>>;
  setBulkRecatCategoryId: Dispatch<SetStateAction<string>>;
  setBulkLoading: (b: boolean) => void;
  updateUrl: (updates: Partial<Record<string, string | undefined>>) => void;
  dateRange: { start: string | undefined; end: string | undefined };
  showToast: (message: string, type?: "success" | "error" | "info") => void;
}

export function createTransactionHandlers(
  getCtx: () => TransactionHandlersContext
) {
  const handlers = {
    async loadTransactions(pageNum: number) {
      const ctx = getCtx();
      const isFirstPage = pageNum === 1;
      try {
        if (isFirstPage) ctx.setLoading(true);
        else ctx.setLoadingMore(true);
        ctx.setError(null);
        const params: Parameters<typeof transactionsApi.list>[0] = {
          include: "category",
          page: pageNum,
          per_page: PER_PAGE,
        };
        if (ctx.searchQuery.trim()) params.q = ctx.searchQuery.trim();
        if (ctx.dateRange.start) params.start_date = ctx.dateRange.start.slice(0, 10);
        if (ctx.dateRange.end) params.end_date = ctx.dateRange.end.slice(0, 10);
        if (ctx.accountId) params.account_id = ctx.accountId;
        if (ctx.categoryId) params.category_id = ctx.categoryId;

        const response = await transactionsApi.list(params);
        const data = Array.isArray(response?.data) ? response.data : [];
        const meta = response?.meta ?? null;
        const currentCtx = getCtx();
        const requestStart = params.start_date ?? "";
        const requestEnd = params.end_date ?? "";
        const currentStart = currentCtx.dateRange?.start ?? "";
        const currentEnd = currentCtx.dateRange?.end ?? "";
        const filterMatches = requestStart === currentStart && requestEnd === currentEnd;
        if (filterMatches) {
          const dedupeById = (arr: Transaction[]) => {
            const seen = new Set<string>();
            return arr.filter((t) => {
              if (seen.has(t.id)) return false;
              seen.add(t.id);
              return true;
            });
          };
          if (isFirstPage) {
            currentCtx.setTransactions(dedupeById(data));
          } else {
            currentCtx.setTransactions((prev) => dedupeById([...prev, ...data]));
          }
          currentCtx.setMeta(meta);
        }
      } catch (err) {
        getCtx().setError("Failed to load transactions");
        console.error(err);
      } finally {
        const c = getCtx();
        if (isFirstPage) c.setLoading(false);
        else c.setLoadingMore(false);
      }
    },

    async loadAccountsAndCategories(
      setAccounts: Dispatch<SetStateAction<Account[]>>,
      setCategories: Dispatch<SetStateAction<Category[]>>
    ) {
      try {
        const [accRes, catRes] = await Promise.all([
          accountsApi.list({ per_page: 200 }),
          categoriesApi.list({ per_page: 200 }),
        ]);
        setAccounts(accRes.data);
        setCategories(catRes.data);
      } catch {
        // non-blocking
      }
    },

    handleSort(field: TransactionSortField) {
      const ctx = getCtx();
      if (ctx.sortField === field) {
        const nextDir = ctx.sortDir === "asc" ? "desc" : "asc";
        ctx.setSortDir(nextDir);
        ctx.updateUrl({ sort: field, dir: nextDir });
      } else {
        ctx.setSortField(field);
        ctx.setSortDir("asc");
        ctx.updateUrl({ sort: field, dir: "asc" });
      }
    },

    clearFilters() {
      const ctx = getCtx();
      ctx.setSearchInput("");
      ctx.setSearchQuery("");
      ctx.setDatePreset("all");
      ctx.setCustomStart("");
      ctx.setCustomEnd("");
      ctx.setAccountId("");
      ctx.setCategoryId("");
      ctx.setPage(1);
      ctx.updateUrl({
        q: undefined,
        date: undefined,
        start: undefined,
        end: undefined,
        account_id: undefined,
        category_id: undefined,
      });
    },

    async handleBulkDelete() {
      const ctx = getCtx();
      if (ctx.selectedIds.size === 0) return;
      if (
        !confirm(
          `Delete ${ctx.selectedIds.size} selected transaction(s)? This cannot be undone.`
        )
      )
        return;
      ctx.setBulkLoading(true);
      try {
        const count = ctx.selectedIds.size;
        await Promise.all(
          Array.from(ctx.selectedIds).map((id) => transactionsApi.delete(id))
        );
        ctx.setSelectedIds(new Set());
        ctx.setBulkMode(false);
        ctx.setPage(1);
        await handlers.loadTransactions(1);
        ctx.showToast(`${count} transaction(s) deleted`);
      } catch {
        getCtx().showToast("Failed to delete some transactions", "error");
      } finally {
        getCtx().setBulkLoading(false);
      }
    },

    async handleBulkRecategorize() {
      const ctx = getCtx();
      if (ctx.selectedIds.size === 0 || !ctx.bulkRecatCategoryId) return;
      ctx.setBulkLoading(true);
      try {
        const count = ctx.selectedIds.size;
        await Promise.all(
          Array.from(ctx.selectedIds).map((id) =>
            transactionsApi.update(id, {
              category_id: ctx.bulkRecatCategoryId,
            })
          )
        );
        ctx.setSelectedIds(new Set());
        ctx.setBulkRecatOpen(false);
        ctx.setBulkRecatCategoryId("");
        ctx.setBulkMode(false);
        ctx.setPage(1);
        await handlers.loadTransactions(1);
        ctx.showToast(`${count} transaction(s) updated`);
      } catch {
        getCtx().showToast("Failed to update some transactions", "error");
      } finally {
        getCtx().setBulkLoading(false);
      }
    },

    handleModalSuccess() {
      const ctx = getCtx();
      ctx.setPage(1);
      handlers.loadTransactions(1);
      ctx.showToast("Transaction saved");
    },

    handleModalDelete() {
      const ctx = getCtx();
      ctx.setPage(1);
      handlers.loadTransactions(1);
      ctx.showToast("Transaction deleted");
    },
  };
  return handlers;
}

export type TransactionHandlers = ReturnType<typeof createTransactionHandlers>;
