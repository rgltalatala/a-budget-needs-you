class BudgetMonth < ApplicationRecord
  belongs_to :budget
  belongs_to :user
  has_many :category_groups, dependent: :destroy
  has_many :summaries, dependent: :destroy

  scope :by_month_desc, -> { order(month: :desc) }

  validates :budget_id, presence: true
  validates :month, presence: true
  validates :user_id, presence: true
  validates :month, uniqueness: { scope: :budget_id }

  # Recalculate available amount based on income and allocations
  def recalculate_available!
    BudgetService.calculate_budget_month_available(self)
  end

  # Apply carryover from this month to the next month
  def apply_carryover_to_next_month!
    CategoryCarryoverService.apply_carryover_to_next_month(self)
  end
end
