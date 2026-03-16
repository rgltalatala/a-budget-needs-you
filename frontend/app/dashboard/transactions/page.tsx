'use client';

import { Card } from '@/components/ui/Card';
import { Loading } from '@/components/ui/Loading';
import { Error } from '@/components/ui/Error';
import { Button } from '@/components/ui/Button';
import { AddTransactionModal } from '@/components/transactions/AddTransactionModal';
import { TransactionTable } from '@/components/transactions/TransactionTable';
import { useTransactionData } from './useTransactionData';

export default function TransactionsPage() {
  const {
    transactions,
    sortedTransactions,
    accounts,
    categories,
    meta,
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
  hasMore,
  hasActiveFilters,
  setPage,
  updateUrl,
    handleSort,
    clearFilters,
    handleBulkDelete,
    handleBulkRecategorize,
    handleModalSuccess,
    handleModalDelete,
  } = useTransactionData();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loading size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center flex-wrap gap-2">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Transactions</h1>
          <p className="mt-2 text-gray-600">View and manage your transactions</p>
        </div>
        <Button onClick={() => { setEditingTransaction(null); setModalOpen(true); }}>
          Add Transaction
        </Button>
      </div>

      <AddTransactionModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditingTransaction(null); }}
        onSuccess={handleModalSuccess}
        onDelete={handleModalDelete}
        transaction={editingTransaction}
      />

      {error && <Error>{error}</Error>}

      <div className="flex flex-wrap items-center gap-3">
        <label htmlFor="transaction-search" className="sr-only">Search by payee</label>
        <input
          id="transaction-search"
          type="text"
          placeholder="Search by payee..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 max-w-xs w-full"
        />
        <label htmlFor="date-preset" className="text-sm font-medium text-gray-700">Date</label>
        <select
          id="date-preset"
          value={datePreset}
          onChange={(e) => {
            const v = e.target.value as import('./useTransactionData').DateRangePreset;
            setDatePreset(v);
            setPage(1);
            updateUrl(v !== 'custom' ? { date: v, start: undefined, end: undefined } : { date: v });
          }}
          className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">All time</option>
          <option value="this_month">This month</option>
          <option value="last_month">Last month</option>
          <option value="last_7">Last 7 days</option>
          <option value="last_30">Last 30 days</option>
          <option value="last_90">Last 90 days</option>
          <option value="custom">Custom</option>
        </select>
        {datePreset === 'custom' && (
          <>
            <input
              type="date"
              value={customStart}
              onChange={(e) => { setCustomStart(e.target.value); setPage(1); updateUrl({ start: e.target.value }); }}
              className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900"
            />
            <span className="text-gray-500">to</span>
            <input
              type="date"
              value={customEnd}
              onChange={(e) => { setCustomEnd(e.target.value); setPage(1); updateUrl({ end: e.target.value }); }}
              className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900"
            />
          </>
        )}
        <label htmlFor="filter-account" className="text-sm font-medium text-gray-700">Account</label>
        <select
          id="filter-account"
          value={accountId}
          onChange={(e) => { setAccountId(e.target.value); setPage(1); updateUrl({ account_id: e.target.value || undefined }); }}
          className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All accounts</option>
          {accounts.map((a) => (
            <option key={a.id} value={a.id}>{a.name}</option>
          ))}
        </select>
        <label htmlFor="filter-category" className="text-sm font-medium text-gray-700">Category</label>
        <select
          id="filter-category"
          value={categoryId}
          onChange={(e) => { setCategoryId(e.target.value); setPage(1); updateUrl({ category_id: e.target.value || undefined }); }}
          className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        {hasActiveFilters && (
          <Button variant="outline" size="sm" onClick={clearFilters}>
            Clear filters
          </Button>
        )}
      </div>

      {bulkMode && selectedIds.size > 0 && (
        <div className="flex flex-wrap items-center gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200">
          <span className="text-sm font-medium text-gray-700">
            {selectedIds.size} selected
          </span>
          <Button variant="outline" size="sm" onClick={handleBulkDelete} disabled={bulkLoading}>
            {bulkLoading ? 'Deleting…' : 'Delete selected'}
          </Button>
          <Button variant="outline" size="sm" onClick={() => setBulkRecatOpen(true)} disabled={bulkLoading}>
            Recategorize
          </Button>
          <Button variant="outline" size="sm" onClick={() => { setSelectedIds(new Set()); setBulkMode(false); }}>
            Cancel
          </Button>
        </div>
      )}

      {bulkRecatOpen && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/50">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-sm w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Recategorize {selectedIds.size} transaction(s)</h3>
            <label className="block text-sm font-medium text-gray-700 mb-1">New category</label>
            <select
              value={bulkRecatCategoryId}
              onChange={(e) => setBulkRecatCategoryId(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-gray-900 mb-4"
            >
              <option value="">Select category</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" size="sm" onClick={() => { setBulkRecatOpen(false); setBulkRecatCategoryId(''); }}>
                Cancel
              </Button>
              <Button size="sm" onClick={handleBulkRecategorize} disabled={!bulkRecatCategoryId || bulkLoading}>
                {bulkLoading ? 'Updating…' : 'Update'}
              </Button>
            </div>
          </div>
        </div>
      )}

      <Card className="border-2 border-gray-300">
        {transactions.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-600">
              {hasActiveFilters ? 'No transactions match your filters.' : 'No transactions yet'}
            </p>
            {!hasActiveFilters && (
              <p className="text-sm text-gray-500 mt-1">Press <kbd className="px-1.5 py-0.5 bg-gray-100 rounded text-xs font-mono">N</kbd> to add one.</p>
            )}
            {hasActiveFilters ? (
              <Button variant="outline" size="sm" className="mt-4" onClick={clearFilters}>
                Clear filters
              </Button>
            ) : (
              <Button className="mt-4" onClick={() => { setEditingTransaction(null); setModalOpen(true); }}>
                Create your first transaction
              </Button>
            )}
          </div>
        ) : (
          <>
            <div className="flex justify-end mb-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => { setBulkMode(!bulkMode); if (bulkMode) setSelectedIds(new Set()); }}
              >
                {bulkMode ? 'Cancel select' : 'Select'}
              </Button>
            </div>
            <TransactionTable
              transactions={sortedTransactions}
              sortField={sortField}
              sortDir={sortDir}
              onSort={handleSort}
              onRowClick={
                bulkMode
                  ? undefined
                  : (t) => { setEditingTransaction(t); setModalOpen(true); }
              }
              emptyMessage={hasActiveFilters ? 'No transactions match your filters.' : 'No transactions yet'}
              sentinelRef={sentinelRef}
              showSentinel={hasMore}
              selectable={bulkMode}
              selectedIds={selectedIds}
              onSelectionChange={setSelectedIds}
            />
          </>
        )}
      </Card>
    </div>
  );
}
