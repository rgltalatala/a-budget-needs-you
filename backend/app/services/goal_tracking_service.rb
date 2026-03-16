# Service class to track goal progress
class GoalTrackingService
  def self.calculate_progress(goal, as_of_date: Date.today)
    new(goal, as_of_date).calculate_progress
  end

  def initialize(goal, as_of_date = Date.today)
    @goal = goal
    @as_of_date = as_of_date
  end

  def calculate_progress
    case @goal.goal_type
    when "needed_for_spending"
      calculate_needed_for_spending_progress
    when "target_savings_balance"
      calculate_target_savings_balance_progress
    when "monthly_savings_builder"
      calculate_monthly_savings_builder_progress
    else
      { progress: 0, percentage: 0, status: "unknown" }
    end
  end

  private

  def calculate_needed_for_spending_progress
    # Needed For Spending: fund up to this amount, with the ability to spend from it along the way
    # Progress = current balance / target_amount (can be > 100% if overfunded, < 0% if overspent)
    current_balance = calculate_current_category_balance
    target_amount = @goal.target_amount || 0
    
    return { progress: 0, percentage: 0, status: "no_target" } if target_amount.zero?

    percentage = (current_balance / target_amount * 100).round(2)
    
    status = if percentage >= 100
      "fully_funded"
    elsif percentage >= 75
      "on_track"
    elsif percentage >= 50
      "in_progress"
    elsif percentage >= 0
      "underfunded"
    else
      "overspent"
    end

    result = {
      progress: current_balance,
      target: target_amount,
      percentage: percentage,
      status: status,
      remaining: [target_amount - current_balance, 0].max
    }
    result[:overspent] = [current_balance * -1, 0].max if current_balance < 0
    result
  end

  def calculate_target_savings_balance_progress
    # Target Savings Balance: save this amount over time and maintain the balance by replenishing any money spent
    # Progress = current balance / target_amount
    # If balance drops below target, goal is to replenish it
    current_balance = calculate_current_category_balance
    target_amount = @goal.target_amount || 0
    
    return { progress: 0, percentage: 0, status: "no_target" } if target_amount.zero?

    percentage = (current_balance / target_amount * 100).round(2)
    
    status = if percentage >= 100
      "maintained"
    elsif percentage >= 75
      "on_track"
    elsif percentage >= 50
      "in_progress"
    elsif percentage > 0
      "building"
    else
      "needs_replenishment"
    end

    {
      progress: current_balance,
      target: target_amount,
      percentage: percentage,
      status: status,
      remaining: [target_amount - current_balance, 0].max,
      needs_replenishment: current_balance < target_amount
    }
  end

  def calculate_monthly_savings_builder_progress
    # Monthly Savings Builder: contribute this amount every month, no matter what, until you disable this Target
    # Progress = sum of monthly contributions / (target_amount * number of months since goal created)
    target_amount = @goal.target_amount || 0
    
    return { progress: 0, percentage: 0, status: "no_target" } if target_amount.zero?

    # Calculate months since goal was created
    months_since_creation = ((@as_of_date.year - @goal.created_at.year) * 12) + 
                            (@as_of_date.month - @goal.created_at.month)
    months_since_creation = [months_since_creation, 1].max # At least 1 month
    
    # Sum all monthly contributions (allotted amounts) since goal creation
    total_contributed = calculate_total_monthly_contributions
    
    expected_total = target_amount * months_since_creation
    percentage = expected_total > 0 ? (total_contributed / expected_total * 100).round(2) : 0
    
    status = if percentage >= 100
      "on_track"
    elsif percentage >= 75
      "mostly_on_track"
    elsif percentage >= 50
      "behind"
    else
      "significantly_behind"
    end

    {
      progress: total_contributed,
      target: expected_total,
      monthly_target: target_amount,
      percentage: percentage,
      status: status,
      months_counted: months_since_creation,
      remaining: [expected_total - total_contributed, 0].max
    }
  end

  def calculate_current_category_balance
    # Get the most recent category_month balance for the as_of_date month
    month = @as_of_date.beginning_of_month
    category_month = CategoryMonth
      .where(category: @goal.category, user: @goal.user)
      .where(month: month)
      .first

    category_month&.balance || 0
  end

  def calculate_accumulated_balance_until(end_date)
    # Sum all positive balances (allotted - spent) for category_months up to end_date
    category_months = CategoryMonth
      .where(category: @goal.category, user: @goal.user)
      .where("month <= ?", end_date.beginning_of_month)
      .where("balance > 0")
    
    category_months.sum(:balance)
  end

  def calculate_total_monthly_contributions
    # Sum all allotted amounts for category_months since goal creation
    start_month = @goal.created_at.beginning_of_month
    end_month = @as_of_date.beginning_of_month
    
    category_months = CategoryMonth
      .where(category: @goal.category, user: @goal.user)
      .where("month >= ? AND month <= ?", start_month, end_month)
    
    category_months.sum(:allotted)
  end
end
