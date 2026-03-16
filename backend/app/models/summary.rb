class Summary < ApplicationRecord
  belongs_to :budget_month
  belongs_to :user

  validates :budget_month_id, presence: true
  validates :user_id, presence: true
  validates :budget_month_id, uniqueness: true

  # Recalculate available amount based on income, carryover, and allocations
  def recalculate_available!
    BudgetService.calculate_budget_month_available(budget_month)
  end

  # Calculate carryover from previous month's categories
  def calculate_carryover!
    CategoryCarryoverService.calculate_carryover_for_month(budget_month)
  end
end
