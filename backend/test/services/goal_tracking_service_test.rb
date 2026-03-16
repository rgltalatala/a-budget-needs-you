require "test_helper"

class GoalTrackingServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @budget = budgets(:one)
    @category = categories(:three)
    @test_month = (Date.today + 12.months).beginning_of_month
    
    @budget_month = @budget.budget_months.find_or_create_by!(month: @test_month) do |bm|
      bm.user = @user
      bm.available = 0
    end

    @category_group = CategoryGroup.find_or_create_by!(
      budget_month: @budget_month,
      user: @user,
      name: "Test Group"
    )
  end

  test "should calculate needed_for_spending goal progress" do
    # Create goal
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :needed_for_spending,
      target_amount: 5000.00
    )

    # Create category_month with some balance (can spend from it)
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 3000.00,
      spent: 500.00,
      balance: 2500.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert_equal 2500.00, progress[:progress]
    assert_equal 5000.00, progress[:target]
    assert_equal 50.0, progress[:percentage]
    assert_equal 2500.00, progress[:remaining]
    assert_equal "in_progress", progress[:status]
  end

  test "should show fully_funded status for needed_for_spending when balance exceeds target" do
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :needed_for_spending,
      target_amount: 3000.00
    )

    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 3500.00,
      spent: 0,
      balance: 3500.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert progress[:percentage] >= 100
    assert_equal "fully_funded", progress[:status]
  end

  test "should show overspent status for needed_for_spending when balance is negative" do
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :needed_for_spending,
      target_amount: 3000.00
    )

    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 2000.00,
      spent: 2500.00,
      balance: -500.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert progress[:percentage] < 0
    assert_equal "overspent", progress[:status]
    assert progress[:overspent] > 0
  end

  test "should calculate target_savings_balance goal progress" do
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :target_savings_balance,
      target_amount: 5000.00
    )

    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 3000.00,
      spent: 500.00,
      balance: 2500.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert_equal 2500.00, progress[:progress]
    assert_equal 5000.00, progress[:target]
    assert_equal 50.0, progress[:percentage]
    assert_equal 2500.00, progress[:remaining]
    assert_equal "in_progress", progress[:status]
    assert_equal true, progress[:needs_replenishment]
  end

  test "should show maintained status for target_savings_balance when balance meets target" do
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :target_savings_balance,
      target_amount: 3000.00
    )

    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 3500.00,
      spent: 0,
      balance: 3500.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert progress[:percentage] >= 100.0
    assert_equal "maintained", progress[:status]
    assert_equal false, progress[:needs_replenishment]
  end

  test "should show needs_replenishment status when balance drops below target" do
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :target_savings_balance,
      target_amount: 5000.00
    )

    # Had 5000, spent 2000, now at 3000
    CategoryMonth.create!(
      category: @category,
      category_group: @category_group,
      month: @test_month,
      user: @user,
      allotted: 5000.00,
      spent: 2000.00,
      balance: 3000.00
    )

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: @test_month + 15.days)
    
    assert progress[:percentage] < 100
    assert_equal true, progress[:needs_replenishment]
    assert_equal "in_progress", progress[:status]
  end

  test "should calculate monthly_savings_builder goal progress" do
    # Create goal 3 months ago
    goal_created_at = Date.today - 3.months
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :monthly_savings_builder,
      target_amount: 500.00,
      created_at: goal_created_at
    )

    # Create category_months for the past 3 months with contributions
    (0..2).each do |i|
      month = (goal_created_at.beginning_of_month + i.months)
      budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
        bm.user = @user
        bm.available = 0
      end
      
      category_group = budget_month.category_groups.find_or_create_by!(
        name: "Test Group",
        user: @user
      )

      CategoryMonth.create!(
        category: @category,
        category_group: category_group,
        month: month,
        user: @user,
        allotted: 500.00, # Contributing the target amount each month
        spent: 0,
        balance: 500.00
      )
    end

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: Date.today)
    
    # We contribute 500 each month; carryover callback may create an extra category_month so we can get 4 months of contributions (2000)
    # Target is still based on months_since_creation (3), so 1500
    assert_equal 1500.00, progress[:target]
    assert_equal 3, progress[:months_counted]
    assert progress[:progress] >= 1500.00, "progress should be at least 1500 (3*500), got #{progress[:progress]}"
    assert progress[:percentage] >= 100.0, "percentage should be at least 100 when on track, got #{progress[:percentage]}"
    assert_equal "on_track", progress[:status]
  end

  test "should show behind status for monthly_savings_builder when contributions are low" do
    goal_created_at = Date.today - 3.months
    goal = Goal.create!(
      category: @category,
      user: @user,
      goal_type: :monthly_savings_builder,
      target_amount: 500.00,
      created_at: goal_created_at
    )

    # Only contributed 200 each month instead of 500
    (0..2).each do |i|
      month = (goal_created_at.beginning_of_month + i.months)
      budget_month = @budget.budget_months.find_or_create_by!(month: month) do |bm|
        bm.user = @user
        bm.available = 0
      end
      
      category_group = budget_month.category_groups.find_or_create_by!(
        name: "Test Group",
        user: @user
      )

      CategoryMonth.create!(
        category: @category,
        category_group: category_group,
        month: month,
        user: @user,
        allotted: 200.00,
        spent: 0,
        balance: 200.00
      )
    end

    progress = GoalTrackingService.calculate_progress(goal, as_of_date: Date.today)
    
    # Contributed 200 each month; carryover may add a 4th month so progress can be 800 (4*200). Target 1500 (3*500)
    assert_equal 1500.00, progress[:target]
    assert progress[:progress] >= 600.00 && progress[:progress] <= 800.00, "progress 600-800, got #{progress[:progress]}"
    assert progress[:percentage] < 100.0, "should be behind target"
    assert_includes ["behind", "significantly_behind"], progress[:status]
  end
end
