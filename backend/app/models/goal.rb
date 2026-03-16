class Goal < ApplicationRecord
  belongs_to :category
  belongs_to :user

  scope :by_goal_type, ->(goal_type) { where(goal_type: goal_type) }

  validates :category_id, presence: true
  validates :goal_type, presence: true
  validates :user_id, presence: true
  validates :category_id, uniqueness: true

  enum :goal_type, {
    needed_for_spending: "needed_for_spending",
    target_savings_balance: "target_savings_balance",
    monthly_savings_builder: "monthly_savings_builder"
  }

  # Calculate goal progress
  def progress(as_of_date: Date.today)
    GoalTrackingService.calculate_progress(self, as_of_date: as_of_date)
  end
end
