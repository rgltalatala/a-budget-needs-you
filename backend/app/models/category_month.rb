class CategoryMonth < ApplicationRecord
  belongs_to :category
  belongs_to :category_group, optional: true
  belongs_to :user

  scope :creation_order, -> { order(:created_at) }
  scope :for_month, ->(month) { where(month: month) }
  scope :for_category_groups, ->(group_ids) { where(category_group_id: group_ids) }

  validates :category_id, presence: true
  validates :user_id, presence: true
  validates :month, presence: true

  # Calculate balance based on allotted and spent
  before_save :calculate_balance
  # Recalculate budget available when allotted changes
  after_save :recalculate_budget_available, if: :saved_change_to_allotted?

  # Recalculate spent amount from transactions
  def recalculate_spent!
    # For income categories, spent should always be 0
    if category.name.downcase == "income"
      self.spent = 0.0
    else
      # For expense categories, sum only negative amounts and take absolute value
      negative_amounts = Transaction
        .where(category_id: category_id)
        .where(user_id: user_id)
        .where("date >= ? AND date < ?", month, month.next_month)
        .where("amount < 0")
        .sum(:amount)
      
      # Convert to positive (spent is always positive)
      self.spent = negative_amounts.abs
    end
    save!
  end

  private

  def calculate_balance
    self.balance = (allotted || 0) - (spent || 0)
  end

  def recalculate_budget_available
    # Find the budget_month for this category_month's month
    # CategoryMonth belongs to a category_group, which belongs to a budget_month
    return unless category_group

    budget_month = category_group.budget_month
    return unless budget_month

    BudgetService.calculate_budget_month_available(budget_month)
    # When allotted changes, re-apply carryover to the next month and cascade so following months stay in sync
    BudgetService.refresh_carryover_to_following_months(budget_month) unless Thread.current[:refreshing_carryover]
  end
end

