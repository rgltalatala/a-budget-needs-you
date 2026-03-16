'use client';

import { useEffect, useState, useCallback, useMemo, useRef } from 'react';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import { transactionsApi } from '@/lib/api';
import { sortTransactions, type TransactionSortField, type SortDir } from '@/lib/transactions';
import { getDateRangeForPreset } from '@/lib/date';
import { useToast } from '@/contexts/ToastContext';
import type { Transaction, Account, Category } from '@/types/api';
import {
  getInitialFilters,
  createTransactionHandlers,
  type DateRangePreset,
} from './transactionHandlers';

export type { TransactionSortField, SortDir, DateRangePreset };

export function useTransactionData() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const { showToast } = useToast();
  const initial = useMemo(
    () => getInitialFilters(searchParams),
    [searchParams]
  );

  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [meta, setMeta] = useState<{
    current_page: number;
    per_page: number;
    total_pages: number;
    total_count: number;
  } | null>(null);
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState(initial.q);
  const [searchInput, setSearchInput] = useState(initial.q);
  const [sortField, setSortField] = useState<TransactionSortField>(initial.sort);
  const [sortDir, setSortDir] = useState<SortDir>(initial.dir);
  const [datePreset, setDatePreset] = useState<DateRangePreset>(initial.date);
  const [customStart, setCustomStart] = useState(initial.start);
  const [customEnd, setCustomEnd] = useState(initial.end);
  const [accountId, setAccountId] = useState<string>(initial.account_id);
  const [categoryId, setCategoryId] = useState<string>(initial.category_id);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  const [bulkMode, setBulkMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkRecatOpen, setBulkRecatOpen] = useState(false);
  const [bulkRecatCategoryId, setBulkRecatCategoryId] = useState('');
  const [bulkLoading, setBulkLoading] = useState(false);
  const sentinelRef = useRef<HTMLDivElement | null>(null);

  const dateRange = useMemo(
    () => getDateRangeForPreset(datePreset, customStart, customEnd),
    [datePreset, customStart, customEnd]
  );

  // Ref holding current filter state so partial URL updates (e.g. search debounce) don't drop other params when searchParams is stale
  const currentFiltersRef = useRef({
    q: searchQuery,
    sort: sortField,
    dir: sortDir,
    date: datePreset,
    start: customStart,
    end: customEnd,
    account_id: accountId,
    category_id: categoryId,
  });
  currentFiltersRef.current = {
    q: searchQuery,
    sort: sortField,
    dir: sortDir,
    date: datePreset,
    start: customStart,
    end: customEnd,
    account_id: accountId,
    category_id: categoryId,
  };

  const lastUpdateUrlAtRef = useRef(0);

  const updateUrl = useCallback(
    (
      updates: {
        q?: string;
        sort?: string;
        dir?: string;
        date?: string;
        start?: string;
        end?: string;
        account_id?: string;
        category_id?: string;
      },
      options?: { skipRecordingTime?: boolean }
    ) => {
      if (!options?.skipRecordingTime) lastUpdateUrlAtRef.current = Date.now();
      const cur = currentFiltersRef.current;
      const params = new URLSearchParams();
      const merged = { ...cur, ...updates };
      if (merged.q) params.set('q', merged.q);
      if (merged.sort) params.set('sort', merged.sort);
      if (merged.dir) params.set('dir', merged.dir);
      if (merged.date) params.set('date', merged.date);
      if (merged.start) params.set('start', merged.start);
      if (merged.end) params.set('end', merged.end);
      if (merged.account_id) params.set('account_id', merged.account_id);
      if (merged.category_id) params.set('category_id', merged.category_id);
      const query = params.toString();
      const href = query ? `${pathname}?${query}` : pathname ?? '/dashboard/transactions';
      router.replace(href);
    },
    [pathname, router]
  );

  const updateUrlRef = useRef(updateUrl);
  updateUrlRef.current = updateUrl;

  const ctxRef = useRef({
    searchQuery,
    datePreset,
    customStart,
    customEnd,
    accountId,
    categoryId,
    sortField,
    sortDir,
    selectedIds,
    bulkRecatCategoryId,
    setSearchQuery,
    setSearchInput,
    setPage,
    setSortField,
    setSortDir,
    setDatePreset,
    setCustomStart,
    setCustomEnd,
    setAccountId,
    setCategoryId,
    setTransactions,
    setMeta,
    setLoading,
    setLoadingMore,
    setError,
    setSelectedIds,
    setBulkMode,
    setBulkRecatOpen,
    setBulkRecatCategoryId,
    setBulkLoading,
    updateUrl,
    dateRange,
    showToast,
  });
  ctxRef.current = {
    searchQuery,
    datePreset,
    customStart,
    customEnd,
    accountId,
    categoryId,
    sortField,
    sortDir,
    selectedIds,
    bulkRecatCategoryId,
    setSearchQuery,
    setSearchInput,
    setPage,
    setSortField,
    setSortDir,
    setDatePreset,
    setCustomStart,
    setCustomEnd,
    setAccountId,
    setCategoryId,
    setTransactions,
    setMeta,
    setLoading,
    setLoadingMore,
    setError,
    setSelectedIds,
    setBulkMode,
    setBulkRecatOpen,
    setBulkRecatCategoryId,
    setBulkLoading,
    updateUrl,
    dateRange,
    showToast,
  };

  const handlers = useMemo(
    () => createTransactionHandlers(() => ctxRef.current),
    []
  );

  // Sync state from URL when user navigates (e.g. back/forward). If we just called updateUrl, treat URL as stale and push our state instead of overwriting (so "All time" and "This month" both stick). Use skipRecordingTime so this push doesn't reset the timer and cause an infinite loop.
  useEffect(() => {
    const justUpdatedUrl = Date.now() - lastUpdateUrlAtRef.current < 500;
    if (justUpdatedUrl) {
      updateUrlRef.current(
        {
          q: searchQuery || undefined,
          sort: sortField,
          dir: sortDir,
          date: datePreset,
          start: customStart || undefined,
          end: customEnd || undefined,
          account_id: accountId || undefined,
          category_id: categoryId || undefined,
        },
        { skipRecordingTime: true }
      );
      return;
    }
    const next = getInitialFilters(searchParams);
    setSearchQuery(next.q);
    setSearchInput(next.q);
    setSortField(next.sort);
    setSortDir(next.dir);
    setDatePreset(next.date);
    setCustomStart(next.start);
    setCustomEnd(next.end);
    setAccountId(next.account_id);
    setCategoryId(next.category_id);
    setPage(1);
  }, [searchParams, datePreset, customStart, customEnd, searchQuery, sortField, sortDir, accountId, categoryId]);

  // Debounce search input → searchQuery + URL (only when searchInput changes; updateUrl in deps would re-run every render and reset page)
  useEffect(() => {
    const t = setTimeout(() => {
      setSearchQuery(searchInput);
      setPage(1);
      updateUrlRef.current({ q: searchInput.trim() || undefined });
    }, 300);
    return () => clearTimeout(t);
  }, [searchInput]);

  useEffect(() => {
    handlers.loadAccountsAndCategories(setAccounts, setCategories);
  }, [handlers]);

  // When date range or search changes, clear list and meta so we refetch with the new filters
  useEffect(() => {
    setTransactions([]);
    setMeta(null);
  }, [datePreset, customStart, customEnd, searchQuery]);

  // Fetch when page, date range, or search changes
  useEffect(() => {
    handlers.loadTransactions(page);
  }, [handlers, page, dateRange, searchQuery]);

  const openId = searchParams?.get('open');
  useEffect(() => {
    if (!openId) return;
    (async () => {
      try {
        const t = await transactionsApi.get(openId);
        setEditingTransaction(t);
        setModalOpen(true);
        const params = new URLSearchParams(window.location.search);
        params.delete('open');
        const qs = params.toString();
        window.history.replaceState(null, '', window.location.pathname + (qs ? `?${qs}` : ''));
      } catch {
        // ignore
      }
    })();
  }, [openId]);

  const hasMore = Boolean(meta && meta.current_page < meta.total_pages);
  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel || !hasMore || loadingMore || loading) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries[0]?.isIntersecting || !hasMore || loadingMore || loading) return;
        setPage((p) => p + 1);
      },
      { rootMargin: '100px', threshold: 0 }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [hasMore, loadingMore, loading]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'n' && !modalOpen && !['INPUT', 'TEXTAREA', 'SELECT'].includes((e.target as HTMLElement)?.tagName)) {
        e.preventDefault();
        setEditingTransaction(null);
        setModalOpen(true);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [modalOpen]);

  const sortedTransactions = useMemo(
    () => sortTransactions(transactions, sortField, sortDir),
    [transactions, sortField, sortDir]
  );

  // When a date range is set, only show transactions within that range (guards against stale responses or API edge cases)
  const displayedTransactions = useMemo(() => {
    if (!dateRange.start || !dateRange.end) return sortedTransactions;
    const start = dateRange.start.slice(0, 10);
    const end = dateRange.end.slice(0, 10);
    return sortedTransactions.filter((t) => {
      const d = (t.date && String(t.date).slice(0, 10)) || '';
      return d >= start && d <= end;
    });
  }, [sortedTransactions, dateRange.start, dateRange.end]);

  const hasActiveFilters = Boolean(searchQuery || datePreset !== 'all' || accountId || categoryId);

  return {
    // Data
    transactions,
    sortedTransactions: displayedTransactions,
    accounts,
    categories,
    meta,
    page,
    dateRange,
    // Filter/sort state
    searchInput,
    setSearchInput,
    sortField,
    sortDir,
    datePreset,
    setDatePreset,
    customStart,
    setCustomStart,
    customEnd,
    setCustomEnd,
    accountId,
    setAccountId,
    categoryId,
    setCategoryId,
    // UI state
    loading,
    loadingMore,
    error,
    modalOpen,
    setModalOpen,
    editingTransaction,
    setEditingTransaction,
    bulkMode,
    setBulkMode,
    selectedIds,
    setSelectedIds,
    bulkRecatOpen,
    setBulkRecatOpen,
    bulkRecatCategoryId,
    setBulkRecatCategoryId,
    bulkLoading,
    sentinelRef,
    setPage,
    // Derived
    hasMore,
    hasActiveFilters,
    // Handlers
    updateUrl,
    handleSort: handlers.handleSort,
    clearFilters: handlers.clearFilters,
    handleBulkDelete: handlers.handleBulkDelete,
    handleBulkRecategorize: handlers.handleBulkRecategorize,
    handleModalSuccess: handlers.handleModalSuccess,
    handleModalDelete: handlers.handleModalDelete,
  };
}
