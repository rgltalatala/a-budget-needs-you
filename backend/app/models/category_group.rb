class CategoryGroup < ApplicationRecord
  belongs_to :budget_month, optional: true
  belongs_to :user, optional: true
  has_many :categories
  has_many :category_months

  scope :creation_order, -> { order(:created_at) }
  scope :for_budget_month, ->(budget_month) { where(budget_month_id: budget_month.id) }

  validates :name, presence: true
end
