# Service class to handle transaction processing and balance updates
class TransactionService
  def self.process_transaction(transaction)
    new(transaction).process
  end

  def self.revert_transaction(transaction)
    new(transaction).revert
  end

  def initialize(transaction)
    @transaction = transaction
  end

  def process
    update_account_balance
    update_category_month_spending
    # Process income transactions for budget calculations
    BudgetService.process_income_transaction(transaction) if income_transaction?
  end

  def revert
    revert_account_balance
    revert_category_month_spending
    # Revert income transactions for budget calculations
    BudgetService.revert_income_transaction(transaction) if income_transaction?
  end

  private

  attr_reader :transaction

  def update_account_balance
    account = transaction.account
    # Use lock to prevent race conditions in parallel tests
    account.with_lock do
      account.balance += transaction.amount
      account.save!
    end
  end

  def revert_account_balance
    account = transaction.account
    # Use lock to prevent race conditions in parallel tests
    account.with_lock do
      account.balance -= transaction.amount
      account.save!
    end
  end

  def update_category_month_spending
    category_month = find_or_create_category_month
    recalculate_category_month_spending(category_month)
    # Balance is calculated automatically by before_save callback, so we don't need update_category_month_balance
  end

  def revert_category_month_spending
    category_month = find_category_month
    return unless category_month

    recalculate_category_month_spending(category_month)
    # Balance is calculated automatically by before_save callback
  end

  def find_or_create_category_month
    month = transaction.date.beginning_of_month
    category = transaction.category

    # Use find_or_initialize_by and save to avoid race conditions in parallel tests
    category_month = CategoryMonth.find_or_initialize_by(
      category_id: category.id,
      month: month,
      user_id: transaction.user_id
    )
    
    # Set category_group_id if it's a new record
    if category_month.new_record?
      category_month.category_group_id = category.category_group_id
      category_month.save!
    end
    
    category_month
  end

  def find_category_month
    month = transaction.date.beginning_of_month
    CategoryMonth.find_by(
      category_id: transaction.category_id,
      month: month,
      user_id: transaction.user_id
    )
  end

  def recalculate_category_month_spending(category_month)
    # Calculate total spent for this category in this month
    month = category_month.month
    category = category_month.category
    
    # For income categories, spent should always be 0
    if category.name.downcase == "income"
      total_spent = 0.0
    else
      # For expense categories, sum only negative amounts and take absolute value
      # Expenses have negative amounts (money going out)
      negative_amounts = Transaction
        .where(category_id: category_month.category_id, user_id: category_month.user_id)
        .in_month(month)
        .expenses
        .sum(:amount)
      
      # Convert to positive (spent is always positive)
      total_spent = negative_amounts.abs
    end

    # Only update if the value has changed to avoid unnecessary saves
    if category_month.spent != total_spent
      category_month.spent = total_spent
      # Balance will be calculated automatically by before_save callback
      category_month.save!
    end
  end

  def income_transaction?
    # Income transactions are positive amounts in an "Income" category
    return false unless transaction.amount > 0
    
    category = transaction.category
    category.name.downcase == "income"
  end
end
