require "test_helper"

class BudgetMonthTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @test_month = (Date.today + 7.months).beginning_of_month
  end

  test "should recalculate available when called" do
    budget_month = BudgetMonth.create!(
      budget: @budget,
      user: @user,
      month: @test_month,
      available: 0
    )

    summary = Summary.create!(
      budget_month: budget_month,
      user: @user,
      income: 4000.00,
      carryover: 0,
      available: 0
    )

    category_group = CategoryGroup.create!(
      budget_month: budget_month,
      user: @user,
      name: "Test Group"
    )

    category = categories(:three)
    CategoryMonth.create!(
      category: category,
      category_group: category_group,
      month: @test_month,
      user: @user,
      allotted: 1500.00,
      spent: 0
    )

    # Recalculate available
    budget_month.recalculate_available!

    budget_month.reload
    assert_equal 2500.00, budget_month.available
    summary.reload
    assert_equal 2500.00, summary.available
  end
end
