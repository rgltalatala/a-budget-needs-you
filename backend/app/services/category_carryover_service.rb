# Service class to handle category balance carryover between months
class CategoryCarryoverService
  def self.calculate_carryover_for_month(budget_month)
    new(budget_month).calculate_carryover
  end

  def self.apply_carryover_to_next_month(budget_month)
    new(budget_month).apply_carryover
  end

  def initialize(budget_month)
    @budget_month = budget_month
  end

  # Calculate total carryover from all categories in this month
  def calculate_carryover
    month = @budget_month.month
    category_group_ids = @budget_month.category_groups.pluck(:id)
    
    # Sum all category balances (positive = available, negative = overspent)
    total_carryover = CategoryMonth
      .for_category_groups(category_group_ids)
      .for_month(month)
      .sum(:balance)
    
    total_carryover
  end

  # Apply carryover from this month to the next month.
  # Each category's remaining balance (allotted - spent) becomes the next month's default allotted for that category.
  def apply_carryover
    current_month = @budget_month.month
    next_month = current_month.next_month.beginning_of_month

    # Ensure current month's category_months have up-to-date spent/balance from transactions
    category_group_ids = @budget_month.category_groups.pluck(:id)
    CategoryMonth
      .for_category_groups(category_group_ids)
      .for_month(current_month)
      .find_each(&:recalculate_spent!)
    
    # Find or create next month's budget_month
    next_budget_month = @budget_month.budget.budget_months.find_or_create_by!(month: next_month) do |bm|
      bm.user = @budget_month.user
      bm.available = 0
    end

    current_category_months = CategoryMonth
      .for_category_groups(category_group_ids)
      .for_month(current_month)
    
    # For each category, set next month's allotted to this month's remaining balance (available).
    # e.g. Jan Misc allotted $2809, spent $1858.99 → balance $950.01 → Feb Misc starting allotted = $950.01.
    # User can later set Feb allotted to 0 to return that amount to Ready to assign.
    current_category_months.each do |current_cm|
      next_cm = find_or_create_next_category_month(current_cm, next_budget_month, next_month)
      next unless next_cm

      next_cm.allotted = (current_cm.balance || 0)
      next_cm.save!
    end
    
    # Update summary carryover
    update_summary_carryover(next_budget_month)
  end

  private

  def find_or_create_next_category_month(current_cm, next_budget_month, next_month)
    # Find corresponding category_group in next month (by name)
    current_category_group = current_cm.category_group
    return nil unless current_category_group

    next_category_group = next_budget_month.category_groups.find_or_create_by!(
      name: current_category_group.name,
      user: next_budget_month.user
    ) do |cg|
      cg.is_default = current_category_group.is_default
    end

    # Find or create category_month for next month
    CategoryMonth.find_or_create_by!(
      category: current_cm.category,
      category_group: next_category_group,
      month: next_month,
      user: current_cm.user
    ) do |cm|
      cm.allotted = 0
      cm.spent = 0
      cm.balance = 0
    end
  end

  def update_summary_carryover(budget_month)
    summary = budget_month.summaries.first || Summary.create!(
      budget_month: budget_month,
      user: budget_month.user,
      income: 0,
      carryover: 0,
      available: 0
    )

    previous_month = budget_month.month.prev_month.beginning_of_month
    previous_budget_month = budget_month.budget.budget_months.find_by(month: previous_month)

    if previous_budget_month
      # Category balances: each category's remaining (allotted - spent) carries to next month's allotted
      category_carryover = CategoryCarryoverService.calculate_carryover_for_month(previous_budget_month)
      # Ready to assign: previous month's leftover available also carries to this month's Ready to assign
      BudgetService.calculate_budget_month_available(previous_budget_month)
      prev_available = previous_budget_month.reload.available.to_f
      summary.carryover = category_carryover + prev_available
      summary.save!

      BudgetService.calculate_budget_month_available(budget_month)
    end
  end
end
