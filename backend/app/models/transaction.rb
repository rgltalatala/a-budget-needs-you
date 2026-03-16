class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category
  belongs_to :user

  scope :recent_first, -> { order(date: :desc) }
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :from_date, ->(d) { where("date >= ?", d) }
  scope :to_date, ->(d) { where("date <= ?", d) }
  scope :in_month, ->(month) { where("date >= ? AND date < ?", month, month.next_month) }
  scope :search_payee, ->(q) { where("payee ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :expenses, -> { where("amount < 0") }

  validates :date, presence: true
  validates :amount, presence: true, numericality: true
  validates :account_id, presence: true
  validates :category_id, presence: true
  validates :user_id, presence: true

  # Callbacks to handle balance updates
  after_create :process_transaction
  after_update :handle_transaction_update
  after_destroy :revert_transaction

  private

  def process_transaction
    TransactionService.process_transaction(self)
  end

  def handle_transaction_update
    # If amount, date, category, or account changed, we need to recalculate
    if saved_change_to_amount? || saved_change_to_date? || saved_change_to_category_id? || saved_change_to_account_id?
      # Get old values before the update
      old_amount = saved_change_to_amount? ? saved_change_to_amount[0] : amount
      old_date = saved_change_to_date? ? saved_change_to_date[0] : date
      old_category_id = saved_change_to_category_id? ? saved_change_to_category_id[0] : category_id
      old_account_id = saved_change_to_account_id? ? saved_change_to_account_id[0] : account_id

      # Check if old transaction was income
      old_category = Category.find_by(id: old_category_id)
      was_income = old_category&.name&.downcase == "income" && old_amount > 0

      # Revert account balance for old amount (subtract what was added before)
      old_account = Account.find(old_account_id)
      old_account.with_lock do
        old_account.balance -= old_amount
        old_account.save!
      end

      # Revert old category month spending
      revert_old_category_month(old_date, old_category_id)

      # Revert income if it was an income transaction
      if was_income
        # Create a temporary transaction object for reverting income
        old_transaction = Transaction.new(
          amount: old_amount,
          date: old_date,
          category_id: old_category_id,
          user_id: user_id
        )
        # Set the category association so BudgetService can check if it's income
        old_transaction.category = Category.find(old_category_id) if old_category_id
        BudgetService.revert_income_transaction(old_transaction)
      end

      # Reload the current account to ensure we have the latest balance
      account.reload if account_id == old_account_id

      # Process new transaction (with new values) - this will add the new amount
      process_transaction
    end
  end

  def revert_transaction
    TransactionService.revert_transaction(self)
  end

  def revert_old_category_month(old_date, old_category_id)
    month = old_date.beginning_of_month
    category_month = CategoryMonth.find_by(
      category_id: old_category_id,
      month: month,
      user_id: user_id
    )

    return unless category_month

    # Recalculate spending for old category/month
    total_spent = Transaction
      .where(category_id: old_category_id)
      .where(user_id: user_id)
      .where("date >= ? AND date < ?", month, month.next_month)
      .where.not(id: id) # Exclude this transaction since it's being updated
      .sum(:amount)

    category_month.spent = total_spent
    category_month.balance = category_month.allotted - category_month.spent
    category_month.save!
  end
end

