'use client';

import { useMemo, useState, useCallback } from 'react';
import { Button } from '@/components/ui/Button';
import { Loading } from '@/components/ui/Loading';
import { TransactionTable } from '@/components/transactions/TransactionTable';
import { sortTransactions, type TransactionSortField, type SortDir } from '@/lib/transactions';
import type { Transaction } from '@/types/api';

interface AccountTransactionListProps {
  transactions: Transaction[];
  loading: boolean;
  accountName: string;
  accountBalance?: number;
  onAddTransaction: () => void;
  onSelectTransaction: (t: Transaction) => void;
}

export function AccountTransactionList({
  transactions,
  loading,
  accountName,
  accountBalance,
  onAddTransaction,
  onSelectTransaction,
}: AccountTransactionListProps) {
  const [sortField, setSortField] = useState<TransactionSortField>('date');
  const [sortDir, setSortDir] = useState<SortDir>('desc');

  const handleSort = useCallback((field: TransactionSortField) => {
    if (sortField === field) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortDir('asc');
    }
  }, [sortField]);

  const sortedTransactions = useMemo(
    () => sortTransactions(transactions, sortField, sortDir),
    [transactions, sortField, sortDir]
  );

  if (loading) {
    return (
      <div className="py-8 text-center text-gray-600">
        <Loading size="md" />
      </div>
    );
  }

  if (transactions.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-600 mb-2">
          No transactions for this account yet.
        </p>
        <p className="text-sm text-gray-500 mb-4">
          Add your first transaction to start tracking income and expenses for{' '}
          {accountName}.
        </p>
        <Button onClick={onAddTransaction}>Add Transaction</Button>
      </div>
    );
  }

  return (
    <TransactionTable
      transactions={sortedTransactions}
      sortField={sortField}
      sortDir={sortDir}
      onSort={handleSort}
      onRowClick={onSelectTransaction}
      emptyMessage="No transactions for this account yet."
      showRunningBalance={accountBalance !== undefined}
      accountBalance={accountBalance ?? 0}
    />
  );
}
