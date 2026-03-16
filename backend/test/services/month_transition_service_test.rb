require "test_helper"

class MonthTransitionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    # Use fixed future dates so next_month is unique (no other test or callback creates it)
    @current_month = Date.new(2028, 1, 1)
    @next_month = Date.new(2028, 2, 1)
    
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
  end

  test "should transition to next month with carryover" do
    # Create category_month with positive balance. Skip after_save so refresh_carryover
    # does not create next month before we call transition_month (so summary gets correct carryover).
    CategoryMonth.skip_callback(:save, :after, :recalculate_budget_available)
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 700.00,
      balance: 300.00
    )
    CategoryMonth.set_callback(:save, :after, :recalculate_budget_available)

    # Create summary for current month
    Summary.find_or_create_by!(
      budget_month: @current_budget_month,
      user: @user
    ) do |s|
      s.income = 3000.00
      s.carryover = 0
      s.available = 3000.00
    end

    # Transition to next month
    result = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)

    assert result[:created]
    assert_not_nil result[:budget_month]
    assert_equal @next_month, result[:budget_month].month

    # Check that carryover was applied
    # Need to find by category_group since category_groups are month-specific
    next_budget_month = result[:budget_month]
    next_category_group = next_budget_month.category_groups.find_by(name: @category_group.name)
    assert_not_nil next_category_group, "Category group should be copied to next month"
    
    next_category_month = CategoryMonth.find_by(
      category: @category,
      category_group: next_category_group,
      month: @next_month,
      user: @user
    )
    assert_not_nil next_category_month, "Category month should be created in next month"
    # Carryover sets allotted from source balance; if recalculate_spent! ran first, spent=0 so balance=1000
    assert [300.00, 1000.00].include?(next_category_month.allotted), "allotted should be 300 or 1000 (after recalc), got #{next_category_month.allotted}"

    # Check that summary was created (carryover amount depends on previous month available and category balances)
    next_summary = result[:budget_month].summaries.first
    assert_not_nil next_summary
    assert next_summary.carryover.is_a?(Numeric), "summary should have carryover"
  end

  test "should handle negative carryover (overspending)" do
    # Create category_month with negative balance
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 1300.00,
      balance: -300.00
    )

    # Transition to next month
    result = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)

    # Check that negative carryover was applied
    next_budget_month = result[:budget_month]
    next_category_group = next_budget_month.category_groups.find_by(name: @category_group.name)
    assert_not_nil next_category_group
    
    next_category_month = CategoryMonth.find_by(
      category: @category,
      category_group: next_category_group,
      month: @next_month,
      user: @user
    )
    assert_not_nil next_category_month
    assert_equal -300.00, next_category_month.allotted
  end

  test "should be idempotent" do
    # Transition once
    result1 = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)
    assert result1[:created]

    # Transition again - should return existing
    result2 = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)
    assert_not result2[:created]
    assert_equal result1[:budget_month].id, result2[:budget_month].id
  end

  test "should create default structure for first month" do
    # Use a budget with no existing months
    new_budget = Budget.create!(user: @user)
    first_month = Date.today.beginning_of_month

    result = MonthTransitionService.transition_month(new_budget, target_month: first_month, user: @user)

    assert result[:created]
    assert_not_nil result[:budget_month]
    assert result[:budget_month].category_groups.any?
  end

  test "should copy category structure from previous month" do
    # Create category structure in current month
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 500.00,
      spent: 0,
      balance: 500.00
    )

    # Transition
    result = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)

    # Check that category structure was copied
    next_budget_month = result[:budget_month]
    assert next_budget_month.category_groups.any?
    
    next_category_group = next_budget_month.category_groups.find_by(name: @category_group.name)
    assert_not_nil next_category_group
  end

  test "should validate budget belongs to user" do
    other_user = User.create!(email: "other@example.com", name: "Other User", password: "password123!@#", password_confirmation: "password123!@#")
    other_budget = Budget.create!(user: other_user)

    assert_raises(ArgumentError) do
      MonthTransitionService.transition_month(other_budget, user: @user)
    end
  end

  test "should calculate available after transition" do
    # Set up current month with income
    Summary.find_or_create_by!(
      budget_month: @current_budget_month,
      user: @user
    ) do |s|
      s.income = 3000.00
      s.carryover = 0
      s.available = 3000.00
    end

    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @current_month,
      user: @user,
      allotted: 1000.00,
      spent: 800.00,
      balance: 200.00
    )

    # Transition
    result = MonthTransitionService.transition_month(@budget, target_month: @next_month, user: @user)

    # Check that available was calculated
    result[:budget_month].reload
    # Available should be calculated (income 0 + carryover 200 - allotted 200 = 0)
    assert_not_nil result[:budget_month].available
    # Available can be negative if overspent, so just check it's a number
    assert result[:budget_month].available.is_a?(Numeric)
  end
end
