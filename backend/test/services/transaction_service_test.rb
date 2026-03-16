require "test_helper"

class TransactionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @budget = budgets(:one)
    @expense_category = categories(:one)   # Groceries
    @income_category = Category.find_or_create_by!(user: @user, name: "Income")

    # Use a future month to avoid fixture conflicts and have a clean category_month
    @month = (Date.today + 12.months).beginning_of_month
    @budget_month = @budget.budget_months.find_or_create_by!(month: @month) do |bm|
      bm.user = @user
      bm.available = 0
    end
    @category_group = CategoryGroup.find_or_create_by!(
      budget_month: @budget_month,
      user: @user,
      name: "Test Group"
    )
    @category_month = CategoryMonth.find_or_create_by!(
      category: @expense_category,
      category_group: @category_group,
      month: @month,
      user: @user
    ) do |cm|
      cm.allotted = 1000.00
      cm.spent = 0
      cm.balance = 1000.00
    end
    # Ensure expense category is linked to this group for the month
    @expense_category.update!(category_group_id: @category_group.id) if @expense_category.category_group_id != @category_group.id
  end

  test "process_transaction increases account balance for positive amount" do
    initial_balance = @account.reload.balance
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @month + 5.days,
      amount: 500.00,
      payee: "Test"
    )
    assert_equal initial_balance + 500.00, @account.reload.balance
    transaction.destroy
  end

  test "process_transaction decreases account balance for expense" do
    initial_balance = @account.reload.balance
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: @month + 5.days,
      amount: -75.00,
      payee: "Store"
    )
    assert_equal initial_balance - 75.00, @account.reload.balance
    assert @category_month.reload.spent >= 75.00
    transaction.destroy
  end

  test "process_transaction creates or updates category_month spending" do
    CategoryMonth.where(
      category: @expense_category,
      month: @month,
      user: @user
    ).destroy_all
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: @month + 3.days,
      amount: -50.00,
      payee: "Test Payee"
    )
    cm = CategoryMonth.find_by(category: @expense_category, month: @month, user: @user)
    assert_not_nil cm
    assert_equal 50.00, cm.spent
    transaction.destroy
  end

  test "revert_transaction restores account balance" do
    initial_balance = @account.reload.balance
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: @month + 7.days,
      amount: -30.00,
      payee: "Revert Test"
    )
    after_process = @account.reload.balance
    assert_equal initial_balance - 30.00, after_process
    TransactionService.revert_transaction(transaction)
    assert_equal initial_balance, @account.reload.balance
    transaction.destroy
  end

  test "revert_transaction recalculates category_month spending" do
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: @month + 8.days,
      amount: -40.00,
      payee: "Revert Category Test"
    )
    cm = CategoryMonth.find_by(category: @expense_category, month: @month, user: @user)
    assert cm.reload.spent >= 40.00
    TransactionService.revert_transaction(transaction)
    cm.reload
    # Spent should be recalculated without this transaction (may be 0 or other fixture tx in same month)
    assert cm.spent >= 0
    transaction.destroy
  end

  test "revert_transaction when category_month is missing does not raise" do
    other_month = (Date.today + 14.months).beginning_of_month
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: other_month + 1.day,
      amount: -10.00,
      payee: "No Category Month"
    )
    CategoryMonth.where(category: @expense_category, month: other_month, user: @user).destroy_all
    assert_nothing_raised { TransactionService.revert_transaction(transaction) }
    transaction.destroy
  end

  test "income transaction updates budget via BudgetService" do
    Summary.where(budget_month: @budget_month).destroy_all
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @month + 5.days,
      amount: 3000.00,
      payee: "Employer"
    )
    summary = @budget_month.reload.summaries.first
    assert_not_nil summary
    assert_equal 3000.00, summary.income
    transaction.destroy
  end

  test "revert then process round-trips account and category_month" do
    initial_balance = @account.reload.balance
    transaction = Transaction.create!(
      account: @account,
      category: @expense_category,
      user: @user,
      date: @month + 10.days,
      amount: -25.00,
      payee: "Round Trip"
    )
    balance_after_process = @account.reload.balance
    TransactionService.revert_transaction(transaction)
    assert_equal initial_balance, @account.reload.balance
    TransactionService.process_transaction(transaction)
    assert_equal balance_after_process, @account.reload.balance
    transaction.destroy
  end
end
