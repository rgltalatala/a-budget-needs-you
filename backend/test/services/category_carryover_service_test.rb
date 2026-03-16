require "test_helper"

class CategoryCarryoverServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @current_month = (Date.today + 11.months).beginning_of_month
    @next_month = @current_month.next_month.beginning_of_month

    @current_budget_month = @budget.budget_months.find_or_create_by!(month: @current_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    @category_group = CategoryGroup.find_or_create_by!(
      budget_month: @current_budget_month,
      user: @user,
      name: "Test Group"
    )

    @category = categories(:three)
    @account = @user.accounts.first || Account.create!(user: @user, name: "Test Account", account_type: "checking", balance: 0)
  end

  # Create expense transaction(s) so recalculate_spent! sees allotted - spent = remaining balance.
  # total_amount is the expense total (positive number); stored as negative amount in DB.
  def create_expense_transactions(month, category, total_amount)
    Transaction.create!(
      user: @user,
      account: @account,
      category: category,
      date: month + 15.days,
      amount: -total_amount.to_d,
      payee: "Test payee"
    )
  end

  test "should calculate carryover from category balances" do
    # Create category_months with different balances
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 800.00,
      balance: 200.00 # Positive balance = available
    )

    carryover = CategoryCarryoverService.calculate_carryover_for_month(@current_budget_month)
    assert_equal 200.00, carryover
  end

  test "should calculate negative carryover for overspent categories" do
    # Create category_month with negative balance (overspent)
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 1200.00,
      balance: -200.00 # Negative balance = overspent
    )

    carryover = CategoryCarryoverService.calculate_carryover_for_month(@current_budget_month)
    assert_equal -200.00, carryover
  end

  test "should apply carryover to next month" do
    # Current month: allotted 1000, spent 700 → remaining balance 300 carries to next month
    current_cm = CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 0,
      balance: 1000.00
    )
    # Transactions so recalculate_spent! yields spent=700, balance=300
    create_expense_transactions(@current_month, @category, 700.00)

    CategoryCarryoverService.apply_carryover_to_next_month(@current_budget_month)

    next_budget_month = @budget.budget_months.find_by(month: @next_month)
    assert_not_nil next_budget_month
    next_category_group = next_budget_month.category_groups.find_by(name: @category_group.name)
    assert_not_nil next_category_group
    next_cm = CategoryMonth.find_by(
      category: @category,
      category_group: next_category_group,
      month: @next_month,
      user: @user
    )
    assert_not_nil next_cm
    # Next month's allotted = previous month's remaining balance (allotted - spent) = 300
    assert_equal 300.00, next_cm.allotted
  end

  test "should apply negative carryover (overspending) to next month" do
    # Current month: allotted 1000, spent 1300 → remaining balance -300 carries to next month
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 0,
      balance: 1000.00
    )
    create_expense_transactions(@current_month, @category, 1300.00)

    CategoryCarryoverService.apply_carryover_to_next_month(@current_budget_month)

    next_budget_month = @budget.budget_months.find_by(month: @next_month)
    next_category_group = next_budget_month.category_groups.find_by(name: @category_group.name)
    next_cm = CategoryMonth.find_by(
      category: @category,
      category_group: next_category_group,
      month: @next_month,
      user: @user
    )
    # Next month's allotted = previous remaining balance (allotted - spent) = -300
    assert_equal(-300.00, next_cm.allotted)
  end

  test "should update summary carryover when applying carryover" do
    # Current month: allotted 1000, spent 800 (via transactions) → balance 200
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 0,
      balance: 1000.00
    )
    create_expense_transactions(@current_month, @category, 800.00)

    # Summary was created by category_month callback; set income = total_allotted so available = 0
    current_summary = @current_budget_month.summaries.first
    current_summary.update!(income: 1000.00, carryover: 0, available: 0)

    CategoryCarryoverService.apply_carryover_to_next_month(@current_budget_month)

    next_budget_month = @budget.budget_months.find_by(month: @next_month)
    next_summary = next_budget_month.summaries.first
    assert_not_nil next_summary
    # Next month's carryover includes previous month's category balance (allotted - spent) = 200
    assert_equal 200.00, next_summary.carryover
  end
end
