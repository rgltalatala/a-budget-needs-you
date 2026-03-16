require "test_helper"

class BudgetServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @budget_month = budget_months(:one)
    @income_category = Category.find_or_create_by!(user: @user, name: "Income")
    @account = accounts(:one)
  end

  test "should calculate available from income and allocations" do
    # Use a future month to avoid fixture conflicts
    test_month = (Date.today + 3.months).beginning_of_month
    budget_month = @budget.budget_months.find_or_create_by!(month: test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    # Create a summary with income
    summary = Summary.find_or_create_by!(budget_month: budget_month, user: @user) do |s|
      s.income = 3000.00
      s.carryover = 500.00
      s.available = 0
    end

    # Create category groups and category months with allocations
    category_group = CategoryGroup.find_or_create_by!(
      budget_month: budget_month,
      user: @user,
      name: "Test Group"
    )

    category = categories(:three) # Use category three to avoid fixture conflicts
    category_month = CategoryMonth.find_or_create_by!(
      category: category,
      category_group: category_group,
      month: test_month,
      user: @user
    ) do |cm|
      cm.allotted = 2000.00
      cm.spent = 0
    end

    # Calculate available
    available = BudgetService.calculate_budget_month_available(budget_month)

    # Available = income (3000) + carryover (500) - allotted (2000) = 1500
    assert_equal 1500.00, available
    budget_month.reload
    assert_equal 1500.00, budget_month.available
    summary.reload
    assert_equal 1500.00, summary.available
  end

  test "should process income transaction and update budget" do
    # Ensure budget_month exists and summary is clean
    month = (Date.today + 5.months).beginning_of_month
    budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    # Clear any existing summary
    Summary.where(budget_month: budget_month).destroy_all

    # Create income transaction (this will trigger TransactionService which calls BudgetService)
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: month + 5.days,
      amount: 5000.00,
      payee: "Employer"
    )

    # Check that summary was created/updated by the transaction callback
    summary = budget_month.summaries.first
    assert_not_nil summary
    assert_equal 5000.00, summary.income

    # Check that available was calculated
    budget_month.reload
    # Available = income (5000) - allotted (0) = 5000
    assert_equal 5000.00, budget_month.available
    summary.reload
    assert_equal 5000.00, summary.available
  end

  test "should revert income transaction" do
    # Set up budget_month with income
    month = (Date.today + 6.months).beginning_of_month
    budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
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

    # Create income transaction (this will trigger TransactionService which calls BudgetService)
    transaction = Transaction.create!(
      account: @account,
      category: @income_category,
      user: @user,
      date: month + 5.days,
      amount: 2000.00,
      payee: "Employer"
    )

    # Check that income was added by the transaction callback
    summary.reload
    assert_equal 7000.00, summary.income

    # Revert income by destroying the transaction
    transaction.destroy

    # Check that income was reverted
    summary.reload
    assert_equal 5000.00, summary.income
  end

  test "should not process non-income transactions" do
    # Use a future month to avoid fixture summary (e.g. March 2026 has income 3000 in fixtures)
    month = (Date.today + 7.months).beginning_of_month
    budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
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
      date: month + 5.days,
      amount: -100.00,
      payee: "Store"
    )

    # Process should not affect income
    BudgetService.process_income_transaction(transaction)

    summary = budget_month.summaries.first
    if summary
      assert_equal 0.00, summary.income
    else
      # No summary created, which is fine
      assert_nil summary
    end
  end

  test "should recalculate available when category allocation changes" do
    # Use a future month to avoid fixture conflicts
    month = (Date.today + 4.months).beginning_of_month
    budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    summary = Summary.find_or_create_by!(budget_month: budget_month, user: @user) do |s|
      s.income = 3000.00
      s.carryover = 0
      s.available = 3000.00
    end

    category_group = CategoryGroup.find_or_create_by!(
      budget_month: budget_month,
      user: @user,
      name: "Test Group"
    )

    category = categories(:three) # Use category three to avoid fixture conflicts
    category_month = CategoryMonth.find_or_create_by!(
      category: category,
      category_group: category_group,
      month: month,
      user: @user
    ) do |cm|
      cm.allotted = 1000.00
      cm.spent = 0
    end

    # Initial available should be 3000 - 1000 = 2000
    BudgetService.calculate_budget_month_available(budget_month)
    budget_month.reload
    assert_equal 2000.00, budget_month.available

    # Update allocation
    category_month.update!(allotted: 2500.00)

    # Available should be recalculated to 3000 - 2500 = 500
    budget_month.reload
    assert_equal 500.00, budget_month.available
  end
end
