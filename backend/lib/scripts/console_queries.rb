# Rails Console Verification Queries
# Copy and paste these into rails console (rails c) to verify everything works
# Or run: load Rails.root.join("lib/scripts/console_queries.rb")

# ============================================
# BASIC VERIFICATION QUERIES
# ============================================

# 1. Get the test user and verify all associations
user = User.find_by(email: "test@example.com")
puts "User: #{user.name} (#{user.email})"
puts "Account Groups: #{user.account_groups.count}"
puts "Accounts: #{user.accounts.count}"
puts "Categories: #{user.categories.count}"
puts "Transactions: #{user.transactions.count}"

# 2. Verify Account associations
account = user.accounts.first
puts "\nAccount: #{account.name}"
puts "  - User: #{account.user.name}"
puts "  - Account Group: #{account.account_group&.name || 'None'}"
puts "  - Transactions: #{account.transactions.count}"

# 3. Verify Transaction associations
transaction = user.transactions.first
puts "\nTransaction: $#{transaction.amount} on #{transaction.date}"
puts "  - Account: #{transaction.account.name}"
puts "  - Category: #{transaction.category.name}"
puts "  - User: #{transaction.user.name}"
puts "  - Payee: #{transaction.payee || 'None'}"

# 4. Verify Category associations
category = user.categories.first
puts "\nCategory: #{category.name}"
puts "  - User: #{category.user.name}"
puts "  - Transactions: #{category.transactions.count}"

# 5. Verify AccountGroup associations
account_group = user.account_groups.first
puts "\nAccount Group: #{account_group.name}"
puts "  - User: #{account_group.user.name}"
puts "  - Accounts: #{account_group.accounts.count}"

# ============================================
# ADVANCED QUERIES
# ============================================

# Get all transactions for a specific account
checking = Account.find_by(name: "Main Checking")
checking_transactions = checking.transactions.order(date: :desc)
puts "\nChecking Account Transactions:"
checking_transactions.each do |t|
  puts "  #{t.date}: #{t.payee} - $#{t.amount} (#{t.category.name})"
end

# Get all transactions for a specific category
groceries = Category.find_by(name: "Groceries")
grocery_transactions = groceries.transactions.order(date: :desc)
puts "\nGrocery Transactions:"
grocery_transactions.each do |t|
  puts "  #{t.date}: #{t.payee} - $#{t.amount} (from #{t.account.name})"
end

# Get transactions for a date range
recent_transactions = Transaction.where(user: user)
                                 .where(date: 1.week.ago..Date.today)
                                 .order(date: :desc)
puts "\nRecent Transactions (last week):"
recent_transactions.each do |t|
  puts "  #{t.date}: #{t.payee} - $#{t.amount}"
end

# Calculate total spending by category
puts "\nTotal Spending by Category:"
user.categories.each do |cat|
  total = cat.transactions.sum(:amount)
  puts "  #{cat.name}: $#{total}"
end

# Calculate account balances from transactions
puts "\nAccount Balances (calculated from transactions):"
user.accounts.each do |acc|
  calculated_balance = acc.transactions.sum(:amount)
  puts "  #{acc.name}: $#{calculated_balance} (stored: $#{acc.balance})"
end
