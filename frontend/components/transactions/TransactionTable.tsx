'use client';

import { useMemo, type RefObject } from 'react';
import type { Transaction } from '@/types/api';
import type { TransactionSortField, SortDir } from '@/lib/transactions';
import { parseDateOnlyLocal } from '@/lib/date';
import { TransactionRow } from './TransactionRow';

interface TransactionTableProps {
  transactions: Transaction[];
  sortField: TransactionSortField;
  sortDir: SortDir;
  onSort: (field: TransactionSortField) => void;
  onRowClick?: (transaction: Transaction) => void;
  emptyMessage?: string;
  sentinelRef?: RefObject<HTMLDivElement | null>;
  showSentinel?: boolean;
  selectable?: boolean;
  selectedIds?: Set<string>;
  onSelectionChange?: (ids: Set<string>) => void;
  /** When set, show a Running balance column (balance after each tx when ordered by date asc) */
  showRunningBalance?: boolean;
  /** Current account balance; used with showRunningBalance to compute running balances */
  accountBalance?: number;
}

const GRID_COLS = 'grid-cols-[1fr_2fr_1.5fr_6rem]';
const GRID_COLS_SELECT = 'grid-cols-[2.5rem_1fr_2fr_1.5fr_6rem]';
const GRID_COLS_RUNNING = 'grid-cols-[1fr_2fr_1.5fr_6rem_5rem]';
const GRID_COLS_SELECT_RUNNING = 'grid-cols-[2.5rem_1fr_2fr_1.5fr_6rem_5rem]';

export function TransactionTable({
  transactions,
  sortField,
  sortDir,
  onSort,
  onRowClick,
  emptyMessage = 'No transactions yet',
  sentinelRef,
  showSentinel,
  selectable,
  selectedIds = new Set(),
  onSelectionChange,
  showRunningBalance,
  accountBalance = 0,
}: TransactionTableProps) {
  const runningBalanceById = useMemo(() => {
    if (!showRunningBalance) return new Map<string, number>();
    const byDate = [...transactions].sort(
      (a, b) => parseDateOnlyLocal(a.date).getTime() - parseDateOnlyLocal(b.date).getTime()
    );
    const map = new Map<string, number>();
    let running = 0;
    for (const t of byDate) {
      running += t.amount;
      map.set(t.id, running);
    }
    return map;
  }, [showRunningBalance, transactions]);

  const toggleOne = (id: string) => {
    if (!onSelectionChange) return;
    const next = new Set(selectedIds);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    onSelectionChange(next);
  };
  const toggleAll = () => {
    if (!onSelectionChange) return;
    if (selectedIds.size === transactions.length) onSelectionChange(new Set());
    else onSelectionChange(new Set(transactions.map((t) => t.id)));
  };

  if (transactions.length === 0) {
    return (
      <div className="py-8 text-center text-gray-600">
        {emptyMessage}
      </div>
    );
  }

  const withRunning = Boolean(showRunningBalance);
  const gridCols = selectable
    ? (withRunning ? GRID_COLS_SELECT_RUNNING : GRID_COLS_SELECT)
    : (withRunning ? GRID_COLS_RUNNING : GRID_COLS);

  return (
    <div className="min-w-0">
      <div className="min-w-lg">
        <div
          className={`grid ${gridCols} gap-3 py-2 px-2 border-b-2 border-gray-200 text-sm font-medium text-gray-600`}
        >
          {selectable && (
            <button
              type="button"
              onClick={toggleAll}
              className="flex items-center justify-center focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
              aria-label={
                selectedIds.size === transactions.length
                  ? "Deselect all"
                  : "Select all"
              }
            >
              <input
                type="checkbox"
                checked={
                  selectedIds.size === transactions.length &&
                  transactions.length > 0
                }
                ref={(el) => {
                  if (el)
                    el.indeterminate =
                      selectedIds.size > 0 &&
                      selectedIds.size < transactions.length;
                }}
                onChange={() => {}}
                className="rounded border-gray-300"
              />
            </button>
          )}
          <button
            type="button"
            onClick={() => onSort("date")}
            className="flex items-center gap-1 text-left hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
          >
            Date
            {sortField === "date" && (
              <span aria-hidden>{sortDir === "desc" ? "↓" : "↑"}</span>
            )}
          </button>
          <button
            type="button"
            onClick={() => onSort("payee")}
            className="flex items-center gap-1 text-left hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
          >
            Payee
            {sortField === "payee" && (
              <span aria-hidden>{sortDir === "desc" ? "↓" : "↑"}</span>
            )}
          </button>
          <button
            type="button"
            onClick={() => onSort("category")}
            className="flex items-center gap-1 text-left hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
          >
            Category
            {sortField === "category" && (
              <span aria-hidden>{sortDir === "desc" ? "↓" : "↑"}</span>
            )}
          </button>
          <button
            type="button"
            onClick={() => onSort("amount")}
            className="flex items-center gap-1 text-right ml-auto hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
          >
            Amount
            {sortField === "amount" && (
              <span aria-hidden>{sortDir === "desc" ? "↓" : "↑"}</span>
            )}
          </button>
          {withRunning && (
            <span className="text-right text-gray-600">Balance</span>
          )}
        </div>
        {transactions.map((transaction) => (
          <TransactionRow
            key={transaction.id}
            transaction={transaction}
            layout="table"
            onClick={onRowClick ? () => onRowClick(transaction) : undefined}
            leading={
              selectable ? (
                <div
                  className="flex items-center justify-center"
                  onClick={(e) => e.stopPropagation()}
                >
                  <input
                    type="checkbox"
                    checked={selectedIds.has(transaction.id)}
                    onChange={() => toggleOne(transaction.id)}
                    onClick={(e) => e.stopPropagation()}
                    className="rounded border-gray-300"
                  />
                </div>
              ) : undefined
            }
            trailing={
              withRunning ? (
                <span className="text-right text-gray-600 text-sm">
                  ${(runningBalanceById.get(transaction.id) ?? 0).toFixed(2)}
                </span>
              ) : undefined
            }
          />
        ))}
        {showSentinel && (
          <div
            ref={sentinelRef}
            className="h-4 flex items-center justify-center py-4"
            aria-hidden
          />
        )}
      </div>
    </div>
  );
}
