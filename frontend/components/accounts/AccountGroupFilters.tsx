'use client';

import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import type { Account, AccountGroup } from '@/types/api';

interface AccountGroupFiltersProps {
  accountGroups: AccountGroup[];
  accounts: Account[];
  selectedGroupId: string | null;
  onSelectGroupId: (id: string | null) => void;
  onAddGroup: () => void;
  addingAccountGroup: boolean;
}

export function AccountGroupFilters({
  accountGroups,
  accounts,
  selectedGroupId,
  onSelectGroupId,
  onAddGroup,
  addingAccountGroup,
}: AccountGroupFiltersProps) {
  return (
    <Card title="Account groups" className="border-2 border-gray-300">
      <p className="text-gray-600 text-sm mb-2">
        Click a group to show only its accounts.
      </p>
      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={() => onSelectGroupId(null)}
          className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
            selectedGroupId === null
              ? 'bg-blue-600 text-white ring-2 ring-blue-400'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          All accounts
        </button>
        {accountGroups.length === 0 ? (
          <span className="text-gray-500 text-sm">No groups yet.</span>
        ) : (
          accountGroups.map((g) => {
            const count = accounts.filter(
              (a) =>
                a.account_group_id != null &&
                String(a.account_group_id) === String(g.id)
            ).length;
            const isSelected = selectedGroupId === g.id;
            return (
              <button
                key={g.id}
                type="button"
                onClick={() => onSelectGroupId(isSelected ? null : g.id)}
                className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
                  isSelected
                    ? 'bg-blue-600 text-white ring-2 ring-blue-400'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {g.name}
                {count > 0 && (
                  <span className="ml-1 opacity-80">({count})</span>
                )}
              </button>
            );
          })
        )}
        <Button
          variant="outline"
          size="sm"
          onClick={onAddGroup}
          disabled={addingAccountGroup}
        >
          {addingAccountGroup ? 'Adding…' : 'Add group'}
        </Button>
      </div>
    </Card>
  );
}
