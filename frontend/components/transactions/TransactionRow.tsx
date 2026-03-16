'use client';

import type { ReactNode } from 'react';
import type { Transaction } from '@/types/api';
import { formatTransactionDate } from '@/lib/date';

export type TransactionRowLayout = 'table' | 'compact';

interface TransactionRowProps {
  transaction: Transaction;
  onClick?: () => void;
  layout?: TransactionRowLayout;
  leading?: ReactNode;
  /** Optional last cell (e.g. running balance). Adds column when set. */
  trailing?: ReactNode;
}

const TABLE_GRID = 'grid-cols-[1fr_2fr_1.5fr_6rem]';
const TABLE_GRID_LEADING = 'grid-cols-[2.5rem_1fr_2fr_1.5fr_6rem]';
const TABLE_GRID_TRAILING = 'grid-cols-[1fr_2fr_1.5fr_6rem_5rem]';
const TABLE_GRID_BOTH = 'grid-cols-[2.5rem_1fr_2fr_1.5fr_6rem_5rem]';

export function TransactionRow({
  transaction,
  onClick,
  layout = 'table',
  leading,
  trailing,
}: TransactionRowProps) {
  const amountClass =
    transaction.amount < 0 ? 'text-red-600' : 'text-green-600';
  const amountStr = `${transaction.amount < 0 ? '-' : '+'}$${Math.abs(transaction.amount).toFixed(2)}`;

  if (layout === 'compact') {
    return (
      <div
        role={onClick ? 'button' : undefined}
        onClick={onClick}
        className="flex justify-between items-center py-2 border-b border-gray-100 last:border-0 cursor-pointer hover:bg-gray-50 rounded px-2 -mx-2 transition-colors"
      >
        <div>
          <p className="font-medium text-gray-900">
            {transaction.payee || 'No payee'}
          </p>
          <p className="text-sm text-gray-600">
            {formatTransactionDate(transaction.date)}
            {transaction.category && (
              <span className="ml-2 text-gray-500">
                · {transaction.category.name}
              </span>
            )}
          </p>
        </div>
        <p className={`font-medium ${amountClass}`}>{amountStr}</p>
      </div>
    );
  }

  const tableGridClass = leading
    ? (trailing ? TABLE_GRID_BOTH : TABLE_GRID_LEADING)
    : (trailing ? TABLE_GRID_TRAILING : TABLE_GRID);

  return (
    <div
      role={onClick ? 'button' : undefined}
      onClick={onClick}
      className={`grid ${tableGridClass} gap-3 py-3 px-2 border-b border-gray-200 last:border-0 cursor-pointer hover:bg-gray-50 rounded-lg -mx-2 transition-colors items-center`}
    >
      {leading}
      <span className="text-gray-900">
        {formatTransactionDate(transaction.date)}
      </span>
      <span
        className="font-medium text-gray-900 truncate"
        title={transaction.payee || undefined}
      >
        {transaction.payee || 'No payee'}
      </span>
      <span
        className="text-gray-600 truncate"
        title={transaction.category?.name}
      >
        {transaction.category?.name ?? '—'}
      </span>
      <span className={`font-medium text-right ${amountClass}`}>
        {amountStr}
      </span>
      {trailing}
    </div>
  );
}
