'use client';

import type { ReactNode } from 'react';
import { Card } from '@/components/ui/Card';
import type { Account, AccountGroup } from '@/types/api';

interface AccountCardProps {
  account: Account;
  accountGroups: AccountGroup[];
  editMode: boolean;
  selected: boolean;
  onToggleSelect: (id: string) => void;
  onSelect: () => void;
  onAssignToGroup: (account: Account, groupId: string | null) => void;
}

export function AccountCard({
  account,
  accountGroups,
  editMode,
  selected,
  onToggleSelect,
  onSelect,
  onAssignToGroup,
}: AccountCardProps) {
  const title: ReactNode = editMode ? (
    <div className="flex items-center gap-2">
      <input
        type="checkbox"
        checked={selected}
        onChange={() => onToggleSelect(account.id)}
        onClick={(e) => e.stopPropagation()}
        className="rounded border-gray-300"
      />
      <span className="flex-1">{account.name}</span>
    </div>
  ) : (
    account.name
  );

  return (
    <div
      className={`h-full min-h-[120px] ${editMode ? '' : 'cursor-pointer'}`}
      role={editMode ? undefined : 'button'}
      tabIndex={editMode ? undefined : 0}
      onClick={editMode ? undefined : onSelect}
      onKeyDown={
        editMode
          ? undefined
          : (e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onSelect();
              }
            }
      }
    >
      <Card
        title={title}
        className="border-2 border-gray-300 transition-shadow hover:shadow-md h-full flex flex-col"
      >
        <div className="text-2xl font-bold text-gray-900 flex-1 flex items-center">
          ${account.balance.toFixed(2)}
        </div>
        <p className="mt-2 text-sm text-gray-600 capitalize">
          {account.account_type}
        </p>
        <div className="mt-2" onClick={(e) => e.stopPropagation()}>
          <label htmlFor={`group-${account.id}`} className="sr-only">
            Account group
          </label>
          <select
            id={`group-${account.id}`}
            value={account.account_group_id ?? ''}
            onChange={(e) =>
              onAssignToGroup(account, e.target.value || null)
            }
            className="w-full mt-1 px-2 py-1 text-sm border border-gray-300 rounded text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">No group</option>
            {accountGroups.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </div>
      </Card>
    </div>
  );
}
