import { describe, test, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { BudgetCategoryRow } from './BudgetCategoryRow';

const noop = vi.fn();

const defaultProps = {
  cat: { id: '1', name: 'Groceries', is_default: true, category_group_id: null, created_at: '', updated_at: '' },
  cm: undefined,
  goal: undefined,
  budgetMonth: null,
  isEditingName: false,
  editingNameValue: '',
  showEditInputInRow: false,
  editInputRef: { current: null },
  onStartEditName: noop,
  onEditingNameChange: noop,
  onSaveName: noop,
  onCancelEditName: noop,
  isEditingAllotted: false,
  allottedEditValue: '',
  onStartEditAllotted: noop,
  onAllottedEditChange: noop,
  onSaveAllotted: noop,
  onCancelEditAllotted: noop,
  onSelect: noop,
};

describe('BudgetCategoryRow', () => {
  test('renders category name', () => {
    render(<BudgetCategoryRow {...defaultProps} />);
    expect(screen.getByText('Groceries')).toBeInTheDocument();
  });

  test('shows allotted and spent when category month is provided', () => {
    render(
      <BudgetCategoryRow
        {...defaultProps}
        cm={{
          id: 'cm1',
          category_id: '1',
          category_group_id: null,
          month: '2026-03-01',
          allotted: 500,
          spent: 100,
          balance: 400,
          created_at: '',
          updated_at: '',
        }}
      />
    );
    expect(screen.getByText(/Allotted: \$500\.00/)).toBeInTheDocument();
    expect(screen.getByText(/Spent: \$100\.00/)).toBeInTheDocument();
  });

  test('calls onSelect when row is clicked', () => {
    const onSelect = vi.fn();
    render(<BudgetCategoryRow {...defaultProps} onSelect={onSelect} />);
    fireEvent.click(screen.getByRole('button', { name: /groceries/i }));
    expect(onSelect).toHaveBeenCalledTimes(1);
  });
});
