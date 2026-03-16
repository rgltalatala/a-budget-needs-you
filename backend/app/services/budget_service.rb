# Service class to handle budget calculations and income processing
class BudgetService
  def self.calculate_budget_month_available(budget_month)
    new(budget_month).calculate_available
  end

  # Re-apply carryover from this month to the next, then cascade to all following months.
  # Call this when allotted amounts change so that future months reflect the new balances.
  def self.refresh_carryover_to_following_months(budget_month)
    return if budget_month.blank?
    return if Thread.current[:refreshing_carryover]

    next_month_date = budget_month.month.to_date.next_month.beginning_of_month
    next_budget_month = budget_month.budget.budget_months.find_by(month: next_month_date)
    return unless next_budget_month

    Thread.current[:refreshing_carryover] = true
    begin
      CategoryCarryoverService.apply_carryover_to_next_month(budget_month)
    ensure
      Thread.current[:refreshing_carryover] = false
    end

    refresh_carryover_to_following_months(next_budget_month.reload)
  end

  def self.process_income_transaction(transaction)
    new(nil, transaction).process_income
  end

  def self.revert_income_transaction(transaction)
    new(nil, transaction).revert_income
  end

  def initialize(budget_month = nil, transaction = nil)
    @budget_month = budget_month
    @transaction = transaction
  end

  def calculate_available
    return unless @budget_month

    summary = find_or_create_summary
    total_allotted = calculate_total_allotted
    
    # Available = income + carryover - total allotted
    available = (summary.income || 0) + (summary.carryover || 0) - total_allotted
    
    # Update both BudgetMonth and Summary
    @budget_month.update_column(:available, available)
    summary.update_column(:available, available)
    
    available
  end

  def process_income
    return unless income_transaction?(@transaction)

    month = @transaction.date.beginning_of_month
    budget_month = find_budget_month_for_month(month)
    return unless budget_month

    summary = find_or_create_summary_for_budget_month(budget_month)
    
    # Add income amount to summary
    summary.with_lock do
      summary.income += @transaction.amount
      summary.save!
    end

    # Recalculate available amounts
    calculate_available_for_budget_month(budget_month)
  end

  def revert_income
    return unless income_transaction?(@transaction)

    month = @transaction.date.beginning_of_month
    budget_month = find_budget_month_for_month(month)
    return unless budget_month

    summary = budget_month.summaries.first
    return unless summary

    # Subtract income amount from summary
    summary.with_lock do
      summary.income -= @transaction.amount
      summary.save!
    end

    # Recalculate available amounts
    calculate_available_for_budget_month(budget_month)
  end

  private

  def find_or_create_summary
    @budget_month.summaries.first || Summary.create!(
      budget_month: @budget_month,
      user: @budget_month.user,
      income: 0,
      carryover: 0,
      available: 0
    )
  end

  def find_or_create_summary_for_budget_month(budget_month)
    budget_month.summaries.first || Summary.create!(
      budget_month: budget_month,
      user: budget_month.user,
      income: 0,
      carryover: 0,
      available: 0
    )
  end

  def calculate_total_allotted
    # Sum all CategoryMonth.allotted for categories in this budget_month's category_groups
    month = @budget_month.month
    category_group_ids = @budget_month.category_groups.pluck(:id)
    
    CategoryMonth
      .for_category_groups(category_group_ids)
      .for_month(month)
      .sum(:allotted)
  end

  def calculate_available_for_budget_month(budget_month)
    summary = budget_month.summaries.first
    return unless summary

    total_allotted = calculate_total_allotted_for_budget_month(budget_month)
    
    # Available = income + carryover - total allotted
    available = (summary.income || 0) + (summary.carryover || 0) - total_allotted
    
    # Update both BudgetMonth and Summary
    budget_month.update_column(:available, available)
    summary.update_column(:available, available)
  end

  def calculate_total_allotted_for_budget_month(budget_month)
    # Get all category_months for categories in this budget_month's category_groups
    month = budget_month.month
    category_group_ids = budget_month.category_groups.pluck(:id)
    
    CategoryMonth
      .for_category_groups(category_group_ids)
      .for_month(month)
      .sum(:allotted)
  end

  def find_budget_month_for_month(month)
    # Find or create the budget_month for the user and month
    # For now, we'll use the first budget for the user
    # In a real app, you might want to specify which budget
    user = @transaction.user
    budget = user.budgets.first_or_create!
    
    month_start = month.beginning_of_month
    budget.budget_months.find_or_create_by!(month: month_start) do |bm|
      bm.user = user
      bm.available = 0
    end
  end

  def income_transaction?(transaction)
    # Income transactions are positive amounts in an "Income" category
    # Check if category name is "Income" (case insensitive)
    return false unless transaction.amount > 0
    
    category = transaction.category
    category.name.downcase == "income"
  end
end
