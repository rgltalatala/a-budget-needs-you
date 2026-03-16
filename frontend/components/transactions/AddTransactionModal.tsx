'use client';

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { accountsApi, categoriesApi, transactionsApi } from '@/lib/api';
import type { Account, Category, Transaction } from '@/types/api';

interface AddTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  onDelete?: () => void;
  /** When provided, modal is in edit mode */
  transaction?: Transaction | null;
  /** When provided, pre-select this account when adding (not editing) */
  defaultAccountId?: string | null;
}

type TransactionType = 'expense' | 'income';

export function AddTransactionModal({
  isOpen,
  onClose,
  onSuccess,
  onDelete,
  transaction: editTransaction,
  defaultAccountId,
}: AddTransactionModalProps) {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const [accountId, setAccountId] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [payee, setPayee] = useState('');
  const [amountStr, setAmountStr] = useState('');
  const [type, setType] = useState<TransactionType>('expense');
  const [isRecurring, setIsRecurring] = useState(false);
  const [recurringMonths, setRecurringMonths] = useState(12);

  const isEditMode = !!editTransaction;

  const incomeCategories = categories.filter(
    (c) => c.name.toLowerCase() === "income"
  );
  const expenseCategories = categories.filter(
    (c) => c.name.toLowerCase() !== "income"
  );
  const visibleCategories = type === "income" ? incomeCategories : expenseCategories;

  useEffect(() => {
    if (!isOpen) return;
    setError(null);
    if (editTransaction) {
      setAccountId(editTransaction.account_id);
      setCategoryId(editTransaction.category_id);
      setDate(editTransaction.date.slice(0, 10));
      setPayee(editTransaction.payee ?? '');
      setAmountStr(Math.abs(editTransaction.amount).toFixed(2));
      setType(editTransaction.amount >= 0 ? 'income' : 'expense');
      setIsRecurring(false);
    } else {
      resetForm();
    }
    async function load() {
      setLoading(true);
      try {
        const [accountsRes, categoriesRes] = await Promise.all([
          accountsApi.list({ per_page: 100 }),
          categoriesApi.list({ per_page: 200 }),
        ]);
        setAccounts(accountsRes.data);
        setCategories(categoriesRes.data);
        if (!editTransaction) {
          if (accountsRes.data.length > 0 && !accountId) {
            const preferred =
              defaultAccountId && accountsRes.data.some((a) => a.id === defaultAccountId)
                ? defaultAccountId
                : accountsRes.data[0].id;
            setAccountId(preferred);
          }
          if (categoriesRes.data.length > 0 && !categoryId) {
            const defaultCat = categoriesRes.data.find(
              (c) => c.name.toLowerCase() !== 'income'
            );
            if (defaultCat) setCategoryId(defaultCat.id);
          }
        }
      } catch (err) {
        setError('Failed to load accounts and categories');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [isOpen, editTransaction?.id, defaultAccountId]);

  const resetForm = () => {
    setDate(new Date().toISOString().slice(0, 10));
    setPayee('');
    setAmountStr('');
    setType('expense');
    setIsRecurring(false);
    setRecurringMonths(12);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const amount = parseFloat(amountStr);
    if (isNaN(amount) || amount <= 0) {
      setError('Please enter a valid positive amount.');
      return;
    }
    if (!accountId || !categoryId) {
      setError('Please select an account and category.');
      return;
    }
    // Derive sign from category (source of truth): Income category = positive
    const selectedCategory = categories.find((c) => c.id === categoryId);
    const isIncomeCategory = selectedCategory?.name?.toLowerCase() === 'income';
    const finalAmount = isIncomeCategory ? Math.abs(amount) : -Math.abs(amount);

    setSubmitting(true);
    try {
      if (isEditMode && editTransaction) {
        await transactionsApi.update(editTransaction.id, {
          account_id: accountId,
          category_id: categoryId,
          date,
          payee: payee || undefined,
          amount: finalAmount,
        });
        onSuccess();
      } else if (isRecurring) {
        const baseDate = new Date(date);
        for (let i = 0; i < recurringMonths; i++) {
          const d = new Date(baseDate);
          d.setMonth(d.getMonth() + i);
          const txDate = d.toISOString().slice(0, 10);
          await transactionsApi.create({
            account_id: accountId,
            category_id: categoryId,
            date: txDate,
            payee: payee || undefined,
            amount: finalAmount,
          });
        }
        onSuccess();
      } else {
        await transactionsApi.create({
          account_id: accountId,
          category_id: categoryId,
          date,
          payee: payee || undefined,
          amount: finalAmount,
        });
        onSuccess();
      }
      resetForm();
      onClose();
    } catch (err: unknown) {
      const msg =
        (err as { message?: string })?.message ||
        'Failed to create transaction.';
      setError(String(msg));
    } finally {
      setSubmitting(false);
    }
  };

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div
        className="absolute inset-0 bg-black/50"
        onClick={onClose}
        aria-hidden="true"
      />
      <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            {isEditMode ? 'Edit Transaction' : 'Add Transaction'}
          </h2>

          {loading ? (
            <p className="text-gray-600">Loading accounts and categories…</p>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              {error && (
                <div className="p-3 rounded-lg bg-red-50 text-red-700 text-sm">
                  {error}
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Type
                </label>
                <select
                  value={type}
                  onChange={(e) => {
                    const newType = e.target.value as TransactionType;
                    setType(newType);
                    if (newType === "income") {
                      const incomeCat = categories.find(
                        (c) => c.name.toLowerCase() === "income"
                      );
                      setCategoryId(incomeCat?.id ?? "");
                    } else {
                      const expenseCat = categories.find(
                        (c) => c.name.toLowerCase() !== "income"
                      );
                      setCategoryId(expenseCat?.id ?? "");
                    }
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="expense">Expense</option>
                  <option value="income">Income</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Account
                </label>
                <select
                  value={accountId}
                  onChange={(e) => setAccountId(e.target.value)}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select account</option>
                  {accounts.map((a) => (
                    <option key={a.id} value={a.id}>
                      {a.name} (${a.balance.toFixed(2)})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category
                </label>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select category</option>
                  {visibleCategories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              <Input
                label="Date"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
              />

              <Input
                label="Payee (optional)"
                type="text"
                placeholder="e.g. Grocery Store, Netflix"
                value={payee}
                onChange={(e) => setPayee(e.target.value)}
              />

              <Input
                label="Amount"
                type="number"
                step="0.01"
                min="0"
                placeholder="0.00"
                value={amountStr}
                onChange={(e) => setAmountStr(e.target.value)}
                required
              />

              {!isEditMode && (
                <>
                  <div className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      id="recurring"
                      checked={isRecurring}
                      onChange={(e) => setIsRecurring(e.target.checked)}
                      className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    <label
                      htmlFor="recurring"
                      className="text-sm font-medium text-gray-700"
                    >
                      Make recurring (e.g. monthly bill or subscription)
                    </label>
                  </div>

                  {isRecurring && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Repeat monthly for
                  </label>
                  <select
                    value={recurringMonths}
                    onChange={(e) =>
                      setRecurringMonths(parseInt(e.target.value, 10))
                    }
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {[3, 6, 12, 24, 36].map((n) => (
                      <option key={n} value={n}>
                        {n} months
                      </option>
                    ))}
                  </select>
                  <p className="mt-1 text-xs text-gray-500">
                    This will create {recurringMonths} transactions, one per
                    month.
                  </p>
                </div>
                  )}
                </>
              )}

              <div className="flex gap-3 pt-2">
                {isEditMode && onDelete && (
                  <Button
                    type="button"
                    variant="danger"
                    onClick={async () => {
                      if (!editTransaction) return;
                      if (!confirm(`Delete transaction "${editTransaction.payee || 'No payee'}" for $${Math.abs(editTransaction.amount).toFixed(2)}?`)) return;
                      setDeleting(true);
                      try {
                        await transactionsApi.delete(editTransaction.id);
                        onDelete();
                        onClose();
                      } catch {
                        setError('Failed to delete transaction');
                      } finally {
                        setDeleting(false);
                      }
                    }}
                    disabled={submitting || deleting}
                    isLoading={deleting}
                  >
                    Delete
                  </Button>
                )}
                <div className="flex gap-3 flex-1 justify-end">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={onClose}
                    className="flex-1 sm:flex-initial"
                  >
                    Cancel
                  </Button>
                  <Button
                    type="submit"
                    isLoading={submitting}
                    disabled={loading || !accountId || !categoryId || !amountStr || deleting}
                    className="flex-1 sm:flex-initial"
                  >
                    {submitting
                      ? 'Saving…'
                      : isEditMode
                        ? 'Save Changes'
                        : 'Add Transaction'}
                  </Button>
                </div>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
