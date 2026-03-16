class Budget < ApplicationRecord
  belongs_to :user
  has_many :budget_months, dependent: :destroy

  validates :user_id, presence: true

  # Find or create a budget_month for a given month
  def find_or_create_budget_month!(month, user)
    month_start = month.beginning_of_month
    budget_months.find_or_create_by!(month: month_start) do |bm|
      bm.user = user
      bm.available = 0
    end
  end
end
