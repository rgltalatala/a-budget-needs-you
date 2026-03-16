'use client';

import { useEffect, useState, useCallback } from 'react';
import { accountGroupsApi, accountsApi, transactionsApi } from '@/lib/api';
import { Card } from '@/components/ui/Card';
import { Loading } from '@/components/ui/Loading';
import { Error } from '@/components/ui/Error';
import { Button } from '@/components/ui/Button';
import { AddTransactionModal } from '@/components/transactions/AddTransactionModal';
import { AccountGroupFilters } from '@/components/accounts/AccountGroupFilters';
import { AccountCard } from '@/components/accounts/AccountCard';
import { AccountTransactionList } from '@/components/accounts/AccountTransactionList';
import type { Account, AccountGroup, Transaction } from '@/types/api';

export default function AccountsPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [accountGroups, setAccountGroups] = useState<AccountGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedAccount, setSelectedAccount] = useState<Account | null>(null);
  const [accountTransactions, setAccountTransactions] = useState<Transaction[]>([]);
  const [transactionsLoading, setTransactionsLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  const [addingAccount, setAddingAccount] = useState(false);
  const [addingAccountGroup, setAddingAccountGroup] = useState(false);
  const [deletingAccount, setDeletingAccount] = useState(false);
  const [editAccountsMode, setEditAccountsMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(null);
  const [accountSearch, setAccountSearch] = useState('');

  const loadAccounts = useCallback(async () => {
    try {
      setLoading(true);
      const [accountsRes, groupsRes] = await Promise.all([
        accountsApi.list(),
        accountGroupsApi.list({ per_page: 50 }),
      ]);
      setAccounts(accountsRes.data);
      setAccountGroups(groupsRes.data.sort((a, b) => a.sort_order - b.sort_order));
    } catch (err) {
      setError('Failed to load accounts');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadAccountTransactions = useCallback(async (accountId: string) => {
    setTransactionsLoading(true);
    try {
      const response = await transactionsApi.list({
        account_id: accountId,
        per_page: 100,
        include: 'category',
      });
      setAccountTransactions(response.data);
    } catch {
      setError('Failed to load transactions');
      setAccountTransactions([]);
    } finally {
      setTransactionsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAccounts();
  }, [loadAccounts]);

  useEffect(() => {
    if (selectedAccount) {
      loadAccountTransactions(selectedAccount.id);
    } else {
      setAccountTransactions([]);
    }
  }, [selectedAccount, loadAccountTransactions]);

  const handleAddAccount = useCallback(async () => {
    setAddingAccount(true);
    setError(null);
    try {
      await accountsApi.create({ name: 'New Account', balance: 0 });
      loadAccounts();
    } catch (err) {
      setError(
        (err as { message?: string })?.message ?? 'Failed to add account'
      );
    } finally {
      setAddingAccount(false);
    }
  }, [loadAccounts]);

  const handleAddAccountGroup = useCallback(async () => {
    setAddingAccountGroup(true);
    setError(null);
    try {
      await accountGroupsApi.create({
        name: 'New Group',
        sort_order: accountGroups.length,
      });
      loadAccounts();
    } catch (err) {
      setError(
        (err as { message?: string })?.message ?? 'Failed to add account group'
      );
    } finally {
      setAddingAccountGroup(false);
    }
  }, [loadAccounts, accountGroups.length]);

  const handleAssignAccountToGroup = useCallback(
    async (account: Account, accountGroupId: string | null) => {
      setError(null);
      try {
        const updated = await accountsApi.update(account.id, {
          account_group_id: accountGroupId,
        });
        setAccounts((prev) =>
          prev.map((a) => (a.id === account.id ? updated : a))
        );
        if (selectedAccount?.id === account.id) {
          setSelectedAccount(updated);
        }
      } catch (err) {
        setError(
          (err as { message?: string })?.message ?? 'Failed to update account'
        );
      }
    },
    [selectedAccount?.id]
  );

  const handleDeleteAccount = useCallback(
    async (account: Account) => {
      if (!confirm(`Delete "${account.name}"? This cannot be undone.`)) return;
      setDeletingAccount(true);
      setError(null);
      try {
        await accountsApi.delete(account.id);
        if (selectedAccount?.id === account.id) {
          setSelectedAccount(null);
        }
        loadAccounts();
      } catch (err) {
        setError(
          (err as { message?: string })?.message ?? 'Failed to delete account'
        );
      } finally {
        setDeletingAccount(false);
      }
    },
    [selectedAccount?.id, loadAccounts]
  );

  const handleDeleteSelectedAccounts = useCallback(async () => {
    if (selectedIds.size === 0) return;
    if (
      !confirm(
        `Delete ${selectedIds.size} selected account${selectedIds.size > 1 ? 's' : ''}? This cannot be undone.`
      )
    )
      return;
    setError(null);
    try {
      await Promise.all(
        Array.from(selectedIds).map((id) => accountsApi.delete(id))
      );
      if (selectedAccount && selectedIds.has(selectedAccount.id)) {
        setSelectedAccount(null);
      }
      setSelectedIds(new Set());
      setEditAccountsMode(false);
      loadAccounts();
    } catch (err) {
      setError(
        (err as { message?: string })?.message ?? 'Failed to delete accounts'
      );
    }
  }, [selectedIds, selectedAccount, loadAccounts]);

  const toggleSelectAccount = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loading size="lg" />
      </div>
    );
  }

  const filteredByGroup =
    selectedGroupId == null
      ? accounts
      : accounts.filter(
          (a) =>
            a.account_group_id != null &&
            String(a.account_group_id) === String(selectedGroupId)
        );
  const displayedAccounts = accountSearch.trim()
    ? filteredByGroup.filter((a) =>
        a.name.toLowerCase().includes(accountSearch.toLowerCase())
      )
    : filteredByGroup;
  const totalBalance = displayedAccounts.reduce(
    (sum, account) => sum + account.balance,
    0
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center flex-wrap gap-2">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Accounts</h1>
          <p className="mt-2 text-gray-600">Manage your accounts</p>
        </div>
        {!selectedAccount && (
          <div className="flex items-center gap-2">
            <Button
              variant={editAccountsMode ? 'primary' : 'outline'}
              size="sm"
              onClick={() => {
                setEditAccountsMode((prev) => !prev);
                if (editAccountsMode) setSelectedIds(new Set());
              }}
            >
              {editAccountsMode ? 'Done' : 'Edit Accounts'}
            </Button>
            {!editAccountsMode && (
              <Button
                onClick={handleAddAccount}
                isLoading={addingAccount}
                disabled={addingAccount}
              >
                Add Account
              </Button>
            )}
          </div>
        )}
      </div>

      {error && <Error>{error}</Error>}

      {!selectedAccount && (
        <div className="flex flex-wrap items-center gap-2">
          <label htmlFor="account-search" className="sr-only">Search accounts</label>
          <input
            id="account-search"
            type="text"
            placeholder="Search accounts by name..."
            value={accountSearch}
            onChange={(e) => setAccountSearch(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 max-w-xs w-full"
          />
          {accountSearch && (
            <Button variant="outline" size="sm" onClick={() => setAccountSearch('')}>
              Clear
            </Button>
          )}
        </div>
      )}

      {!selectedAccount && (
        <AccountGroupFilters
          accountGroups={accountGroups}
          accounts={accounts}
          selectedGroupId={selectedGroupId}
          onSelectGroupId={setSelectedGroupId}
          onAddGroup={handleAddAccountGroup}
          addingAccountGroup={addingAccountGroup}
        />
      )}

      <Card title="Total Balance" className="border-2 border-gray-300">
        <div className="text-3xl font-bold text-gray-900">
          ${totalBalance.toFixed(2)}
        </div>
      </Card>

      {!selectedAccount && selectedGroupId && (
        <p className="text-sm text-gray-600">
          Showing accounts in{' '}
          <strong>
            {accountGroups.find((g) => g.id === selectedGroupId)?.name ?? 'this group'}
          </strong>
          . Click &quot;All accounts&quot; to show all.
        </p>
      )}

      {selectedAccount ? (
        <div className="space-y-4">
          <div className="flex items-center gap-2 flex-wrap">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setSelectedAccount(null)}
            >
              ← Back to accounts
            </Button>
            <Button
              variant="danger"
              size="sm"
              onClick={() => handleDeleteAccount(selectedAccount)}
              disabled={deletingAccount}
            >
              {deletingAccount ? 'Deleting…' : 'Delete account'}
            </Button>
          </div>
          <Card title={selectedAccount.name} className="border-2 border-gray-300">
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-2xl font-bold text-gray-900">
                    ${selectedAccount.balance.toFixed(2)}
                  </p>
                  <p className="text-sm text-gray-600 capitalize">
                    {selectedAccount.account_type}
                  </p>
                </div>
              </div>
              <h3 className="font-medium text-gray-900 pt-2 border-t border-gray-200">
                Transactions
              </h3>
              <AccountTransactionList
                transactions={accountTransactions}
                loading={transactionsLoading}
                accountName={selectedAccount.name}
                accountBalance={selectedAccount.balance}
                onAddTransaction={() => {
                  setEditingTransaction(null);
                  setModalOpen(true);
                }}
                onSelectTransaction={(t) => {
                  setEditingTransaction(t);
                  setModalOpen(true);
                }}
              />
            </div>
          </Card>
        </div>
      ) : (
        <div className="space-y-4">
          {editAccountsMode && displayedAccounts.length > 0 && (
            <div className="flex items-center justify-between flex-wrap gap-2 p-3 bg-gray-50 rounded-lg border-2 border-gray-300">
              <span className="text-sm text-gray-700">
                {selectedIds.size > 0
                  ? `${selectedIds.size} selected`
                  : 'Select accounts to delete'}
              </span>
              <div className="flex gap-2">
                <Button
                  variant="danger"
                  size="sm"
                  onClick={handleDeleteSelectedAccounts}
                  disabled={selectedIds.size === 0}
                >
                  Delete selected
                </Button>
              </div>
            </div>
          )}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {displayedAccounts.length === 0 ? (
              <div className="col-span-full text-center py-12">
                <p className="text-gray-600">
                  {selectedGroupId
                    ? 'No accounts in this group'
                    : 'No accounts yet'}
                </p>
                {selectedGroupId ? (
                  <Button
                    variant="outline"
                    size="sm"
                    className="mt-4"
                    onClick={() => setSelectedGroupId(null)}
                  >
                    Show all accounts
                  </Button>
                ) : (
                  <Button
                    className="mt-4"
                    onClick={handleAddAccount}
                    isLoading={addingAccount}
                    disabled={addingAccount}
                  >
                    Create your first account
                  </Button>
                )}
              </div>
            ) : (
              displayedAccounts.map((account) => (
                <AccountCard
                  key={account.id}
                  account={account}
                  accountGroups={accountGroups}
                  editMode={editAccountsMode}
                  selected={selectedIds.has(account.id)}
                  onToggleSelect={toggleSelectAccount}
                  onSelect={() => setSelectedAccount(account)}
                  onAssignToGroup={handleAssignAccountToGroup}
                />
              ))
            )}
          </div>
        </div>
      )}

      <AddTransactionModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditingTransaction(null); }}
        defaultAccountId={selectedAccount?.id ?? null}
        onSuccess={async () => {
          const response = await accountsApi.list();
          setAccounts(response.data);
          if (selectedAccount) {
            const updated = response.data.find((a) => a.id === selectedAccount.id);
            if (updated) setSelectedAccount(updated);
            loadAccountTransactions(selectedAccount.id);
          }
        }}
        onDelete={async () => {
          const response = await accountsApi.list();
          setAccounts(response.data);
          if (selectedAccount) {
            const updated = response.data.find((a) => a.id === selectedAccount.id);
            if (updated) setSelectedAccount(updated);
            loadAccountTransactions(selectedAccount.id);
          }
        }}
        transaction={editingTransaction}
      />
    </div>
  );
}
