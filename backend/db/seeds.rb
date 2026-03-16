# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require_relative "seeds_base"

# Create a test user
user = ensure_seed_user("test@example.com", "Test User")

# Create account groups
checking_group = AccountGroup.find_or_create_by!(user: user, name: "Checking Accounts") do |ag|
  ag.sort_order = 1
end

savings_group = AccountGroup.find_or_create_by!(user: user, name: "Savings Accounts") do |ag|
  ag.sort_order = 2
end

# Create accounts
checking_account = Account.find_or_create_by!(user: user, name: "Main Checking") do |a|
  a.account_type = "checking"
  a.balance = 5000.00
  a.account_group = checking_group
end

savings_account = Account.find_or_create_by!(user: user, name: "Emergency Fund") do |a|
  a.account_type = "savings"
  a.balance = 10000.00
  a.account_group = savings_group
end

credit_card = Account.find_or_create_by!(user: user, name: "Credit Card") do |a|
  a.account_type = "credit"
  a.balance = -500.00
  a.account_group = checking_group
end

# Create categories
groceries = Category.find_or_create_by!(user: user, name: "Groceries") do |c|
  c.is_default = true
end

rent = Category.find_or_create_by!(user: user, name: "Rent") do |c|
  c.is_default = true
end

dining_out = Category.find_or_create_by!(user: user, name: "Dining Out") do |c|
  c.is_default = false
end

utilities = Category.find_or_create_by!(user: user, name: "Utilities") do |c|
  c.is_default = true
end

income = Category.find_or_create_by!(user: user, name: "Income") do |c|
  c.is_default = true
end

# Create transactions
Transaction.find_or_create_by!(
  user: user,
  account: checking_account,
  category: groceries,
  date: Date.today - 5.days,
  amount: -125.50
) do |t|
  t.payee = "Whole Foods"
end

Transaction.find_or_create_by!(
  user: user,
  account: checking_account,
  category: rent,
  date: Date.today - 10.days,
  amount: -1500.00
) do |t|
  t.payee = "Landlord"
end

Transaction.find_or_create_by!(
  user: user,
  account: checking_account,
  category: dining_out,
  date: Date.today - 2.days,
  amount: -45.75
) do |t|
  t.payee = "Local Restaurant"
end

Transaction.find_or_create_by!(
  user: user,
  account: checking_account,
  category: utilities,
  date: Date.today - 7.days,
  amount: -85.00
) do |t|
  t.payee = "Electric Company"
end

Transaction.find_or_create_by!(
  user: user,
  account: checking_account,
  category: income,
  date: Date.today - 15.days,
  amount: 3000.00
) do |t|
  t.payee = "Employer"
end

Transaction.find_or_create_by!(
  user: user,
  account: credit_card,
  category: groceries,
  date: Date.today - 3.days,
  amount: -75.25
) do |t|
  t.payee = "Target"
end

puts "Seeded data successfully!"
puts "  - 1 user"
puts "  - 2 account groups"
puts "  - 3 accounts"
puts "  - 5 categories"
puts "  - 6 transactions"
