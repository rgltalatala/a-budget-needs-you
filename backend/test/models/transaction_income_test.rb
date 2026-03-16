require "test_helper"

class TransactionIncomeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @account = accounts(:one)
    @income_category = Category.find_or_create_by!(user: @user, name: "Income")
    @test_month = (Date.today + 8.months).beginning_of_month
  end

  test "should update budget income when income transaction is created" do
    # Create budget_month
    budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    # Clear any existing summary
    Summary.where(budget_month: budget_month).destroy_all

    # Create income transaction
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @test_month + 5.days,
      amount: 3000.00,
      payee: "Employer"
    )

    # Check that summary was created with income
    summary = budget_month.summaries.first
    assert_not_nil summary
    assert_equal 3000.00, summary.income

    # Check that available was calculated
    budget_month.reload
    assert_equal 3000.00, budget_month.available
  end

  test "should update budget income when income transaction is updated" do
    # Create budget_month
    budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    Summary.where(budget_month: budget_month).destroy_all

    # Create income transaction
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @test_month + 5.days,
      amount: 2000.00,
      payee: "Employer"
    )

    summary = budget_month.summaries.first
    assert_equal 2000.00, summary.income

    # Update transaction amount
    transaction.update!(amount: 3500.00)

    # Check that income was updated
    summary.reload
    assert_equal 3500.00, summary.income
    budget_month.reload
    assert_equal 3500.00, budget_month.available
  end

  test "should revert budget income when income transaction is destroyed" do
    # Create budget_month
    budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    Summary.where(budget_month: budget_month).destroy_all
    summary = Summary.create!(
      budget_month: budget_month,
      user: @user,
      income: 5000.00,
      carryover: 0,
      available: 5000.00
    )

    # Create income transaction
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @test_month + 5.days,
      amount: 1000.00,
      payee: "Employer"
    )

    summary.reload
    assert_equal 6000.00, summary.income

    # Destroy transaction
    transaction.destroy

    # Check that income was reverted
    summary.reload
    assert_equal 5000.00, summary.income
    budget_month.reload
    assert_equal 5000.00, budget_month.available
  end

  test "should not process non-income transactions for budget" do
    # Create budget_month
    budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    Summary.where(budget_month: budget_month).destroy_all

    # Create expense transaction (negative amount)
    expense_category = categories(:one)
    transaction = Transaction.create!(
      account: @account,
      category: expense_category,
      user: @user,
      date: @test_month + 5.days,
      amount: -100.00,
      payee: "Store"
    )

    # Check that summary was not created (no income transactions)
    summary = budget_month.summaries.first
    assert_nil summary
  end

  test "should handle income transaction category change" do
    # Create budget_month
    budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    Summary.where(budget_month: budget_month).destroy_all

    # Create income transaction
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: @test_month + 5.days,
      amount: 2000.00,
      payee: "Employer"
    )

    summary = budget_month.summaries.first
    assert_equal 2000.00, summary.income

    # Change to expense category
    expense_category = categories(:one)
    transaction.update!(category: expense_category, amount: -100.00)

    # Income should be reverted
    summary.reload
    assert_equal 0.00, summary.income
  end

  test "should handle income transaction date change between months" do
    old_month = (Date.today + 9.months).beginning_of_month
    new_month = (Date.today + 10.months).beginning_of_month

    # Create budget_months for both months
    old_budget_month = @budget.budget_months.find_or_create_by!(month: old_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    new_budget_month = @budget.budget_months.find_or_create_by!(month: new_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    Summary.where(budget_month: [old_budget_month, new_budget_month]).destroy_all

    # Create income transaction in old month
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: old_month + 5.days,
      amount: 3000.00,
      payee: "Employer"
    )

    old_summary = old_budget_month.summaries.first
    assert_equal 3000.00, old_summary.income

    # Move transaction to new month
    transaction.update!(date: new_month + 5.days)

    # Old month income should be reverted
    old_summary.reload
    assert_equal 0.00, old_summary.income

    # New month should have income
    new_summary = new_budget_month.summaries.first
    assert_not_nil new_summary
    assert_equal 3000.00, new_summary.income
  end
end
