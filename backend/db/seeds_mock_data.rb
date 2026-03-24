# Mock data seed file
# Run with: rails runner db/seeds_mock_data.rb [user_email]
# Adds transactions and budget structure. Base user can be created via seeds.rb or ensure_seed_user.

require_relative "seeds_base"

user_email = ARGV[0] || "test@example.com"
user = User.find_by(email: user_email)

unless user
  puts "User with email #{user_email} not found. Creating with ensure_seed_user..."
  user = ensure_seed_user(user_email, "Mock User")
end

puts "Creating mock data for user: #{user.email}..."

# Helper to coerce values for URLs/params
def iso_month(date)
  date.beginning_of_month.to_date
end

# TEMPLATE_MONTH is defined in seeds_base.rb (February 2026 — categories and groups copy to other months).

# Copy category groups and category_months from source budget month to target. Allotted is 0 by default;
# carryover from the previous month should be applied separately (e.g. via CategoryCarryoverService.apply_carryover_to_next_month).
def copy_budget_month_structure(source_bm, target_bm, user)
  source_bm.category_groups.each do |src_cg|
    target_bm.category_groups.find_or_create_by!(user: user, name: src_cg.name) { |cg| cg.is_default = src_cg.is_default }
  end
  target_bm.reload
  CategoryMonth
    .joins(:category_group)
    .where(category_groups: { budget_month_id: source_bm.id }, month: source_bm.month, user_id: user.id)
    .each do |src_cm|
      target_cg = target_bm.category_groups.find_by(name: src_cm.category_group.name, user_id: user.id)
      next unless target_cg
      target_cm = CategoryMonth.find_or_initialize_by(user: user, category_id: src_cm.category_id, month: target_bm.month)
      target_cm.category_group_id = target_cg.id
      target_cm.allotted = 0
      target_cm.save!
      target_cm.recalculate_spent!
    end
end

# Create or get account groups
checking_group = AccountGroup.find_or_create_by!(user: user, name: "Checking Accounts") do |ag|
  ag.sort_order = 1
end

credit_group = AccountGroup.find_or_create_by!(user: user, name: "Credit Cards") do |ag|
  ag.sort_order = 2
end

savings_group = AccountGroup.find_or_create_by!(user: user, name: "Savings Accounts") do |ag|
  ag.sort_order = 3
end

# Create accounts
# Same name as seeds.rb so db:seed produces one checking account (not "Primary" + "Main").
checking_account = Account.find_or_create_by!(user: user, name: "Main Checking") do |a|
  a.account_type = "checking"
  a.balance = 3500.00
  a.account_group = checking_group
end

credit_card = Account.find_or_create_by!(user: user, name: "Credit Card") do |a|
  a.account_type = "credit"
  a.balance = -1250.00
  a.account_group = credit_group
end

# Emergency Fund (matches base seeds.rb name when both run — paired transfers fund this account)
savings_account = Account.find_or_create_by!(user: user, name: "Emergency Fund") do |a|
  a.account_type = "savings"
  a.balance = 0.0
  a.account_group = savings_group
end

# Create or get categories
income_category = Category.find_or_create_by!(user: user, name: "Income") do |c|
  c.is_default = true
end

groceries_category = Category.find_or_create_by!(user: user, name: "Groceries") do |c|
  c.is_default = true
end

utilities_category = Category.find_or_create_by!(user: user, name: "Utilities") do |c|
  c.is_default = true
end

subscriptions_category = Category.find_or_create_by!(user: user, name: "Subscriptions") do |c|
  c.is_default = false
end

misc_category = Category.find_or_create_by!(user: user, name: "Miscellaneous") do |c|
  c.is_default = false
end

# Credit Card Payment: category exists for transactions/accounts but is not in any budget category group
transfers_category = Category.find_or_create_by!(user: user, name: "Credit Card Payment") do |c|
  c.is_default = false
end

# Savings contributions (paired checking → savings; visible in register + Emergency Fund balance)
savings_category = Category.find_or_create_by!(user: user, name: "Savings") do |c|
  c.is_default = false
end

# Create a budget (or use existing one)
budget = Budget.find_or_create_by!(user: user)

# Build February 2026 as the template month: its categories and category groups carry over to all other months
current_month = iso_month(Date.today)
template_budget_month = budget.find_or_create_budget_month!(TEMPLATE_MONTH, user)

# Create category groups and category_months for the template month (Feb 2026)
income_group = CategoryGroup.find_or_create_by!(
  user: user,
  budget_month: template_budget_month,
  name: "Income"
) { |cg| cg.is_default = true }
bills_group = CategoryGroup.find_or_create_by!(
  user: user,
  budget_month: template_budget_month,
  name: "Bills"
) { |cg| cg.is_default = true }
everyday_group = CategoryGroup.find_or_create_by!(
  user: user,
  budget_month: template_budget_month,
  name: "Everyday"
) { |cg| cg.is_default = true }

# Template category_months with allotments (these carry over when we copy structure)
[
  { category: income_category, group: income_group, allotted: 0.00 },
  { category: utilities_category, group: bills_group, allotted: 250.00 },
  { category: subscriptions_category, group: bills_group, allotted: 100.00 },
  { category: groceries_category, group: everyday_group, allotted: 600.00 },
  { category: misc_category, group: everyday_group, allotted: 300.00 },
].each do |spec|
  cm = CategoryMonth.find_or_initialize_by(user: user, category: spec[:category], month: TEMPLATE_MONTH)
  cm.category_group = spec[:group]
  cm.allotted = spec[:allotted]
  cm.save!
  cm.recalculate_spent!
end

# Current month: use template structure only. Allotted starts at 0; carryover from previous month is applied after all transactions exist (so previous month has correct spent/balance).
budget_month = if current_month == TEMPLATE_MONTH
  template_budget_month
else
  bm = budget.find_or_create_budget_month!(current_month, user)
  copy_budget_month_structure(template_budget_month, bm, user)
  bm.reload
  bm
end

# Link categories to current month's groups so TransactionService attaches new CategoryMonths correctly
income_grp = budget_month.category_groups.find_by(name: "Income")
bills_grp = budget_month.category_groups.find_by(name: "Bills")
everyday_grp = budget_month.category_groups.find_by(name: "Everyday")
income_category.update!(category_group: income_grp) if income_grp && income_category.category_group_id != income_grp.id
utilities_category.update!(category_group: bills_grp) if bills_grp && utilities_category.category_group_id != bills_grp.id
subscriptions_category.update!(category_group: bills_grp) if bills_grp && subscriptions_category.category_group_id != bills_grp.id
groceries_category.update!(category_group: everyday_grp) if everyday_grp && groceries_category.category_group_id != everyday_grp.id
misc_category.update!(category_group: everyday_grp) if everyday_grp && misc_category.category_group_id != everyday_grp.id

# Create income transactions (bi-weekly paychecks for the last 3 months)
puts "Creating income transactions..."
start_date = 3.months.ago.beginning_of_month.to_date
end_date = Date.today

# Bi-weekly income starting from the first Friday of the start month
first_friday = start_date.beginning_of_week(:friday)
first_friday = first_friday < start_date ? first_friday + 7.days : first_friday

current_payday = first_friday
income_amount = 2500.00
income_count = 0

while current_payday <= end_date
  Transaction.find_or_create_by!(
    user: user,
    account: checking_account,
    category: income_category,
    date: current_payday,
    amount: income_amount
  ) do |t|
    t.payee = "Employer - Payroll"
  end
  income_count += 1
  current_payday += 14.days
end

puts "  Created #{income_count} income transactions"

# Emergency Fund: realistic paired transfers (checking → savings) twice per month
puts "Creating Emergency Fund contributions..."
savings_transfer_count = 0
start_date.upto(end_date) do |date|
  next unless [1, 15].include?(date.day)
  # Vary slightly so find_or_create stays unique per event
  amount = date.day == 1 ? 200.0 : 125.0
  Transaction.find_or_create_by!(
    user: user,
    account: checking_account,
    category: savings_category,
    date: date,
    amount: -amount
  ) do |t|
    t.payee = "Transfer to Emergency Fund"
  end
  Transaction.find_or_create_by!(
    user: user,
    account: savings_account,
    category: savings_category,
    date: date,
    amount: amount
  ) do |t|
    t.payee = "Transfer to Emergency Fund"
  end
  savings_transfer_count += 2
end
puts "  Created #{savings_transfer_count / 2} savings transfer events (#{savings_transfer_count} legs)"

# Create recurring bills on credit card (monthly)
puts "Creating recurring bills..."
recurring_bills = [
  { name: "Netflix", amount: -15.99, category: subscriptions_category },
  { name: "Spotify", amount: -9.99, category: subscriptions_category },
  { name: "Gym Membership", amount: -49.99, category: misc_category },
  { name: "Phone Bill", amount: -85.00, category: utilities_category },
  { name: "Internet", amount: -79.99, category: utilities_category },
]

bill_count = 0
start_date.upto(end_date) do |date|
  # Bills are typically due on the 1st of each month
  if date.day == 1
    recurring_bills.each do |bill|
      Transaction.find_or_create_by!(
        user: user,
        account: credit_card,
        category: bill[:category],
        date: date,
        amount: bill[:amount]
      ) do |t|
        t.payee = bill[:name]
      end
      bill_count += 1
    end
  end
end

puts "  Created #{bill_count} recurring bill transactions"

# Create grocery transactions (weekly, varying amounts)
puts "Creating grocery transactions..."
grocery_stores = ["Whole Foods", "Target", "Safeway", "Trader Joe's", "Costco"]
grocery_count = 0

start_date.upto(end_date) do |date|
  # Groceries typically on weekends
  if date.saturday? || date.sunday?
    # Randomly skip some weekends (not every weekend)
    next if rand < 0.3
    
    Transaction.find_or_create_by!(
      user: user,
      account: credit_card,
      category: groceries_category,
      date: date,
      amount: -(rand(50..200).to_f.round(2))
    ) do |t|
      t.payee = grocery_stores.sample
    end
    grocery_count += 1
  end
end

puts "  Created #{grocery_count} grocery transactions"

# Create miscellaneous spending (random throughout the month)
puts "Creating miscellaneous transactions..."
misc_payees = ["Amazon", "Starbucks", "Gas Station", "Restaurant", "Uber", "Coffee Shop", "Pharmacy"]
misc_count = 0

start_date.upto(end_date) do |date|
  # Random miscellaneous spending (about 2-3 times per week)
  if rand < 0.3
    Transaction.find_or_create_by!(
      user: user,
      account: credit_card,
      category: misc_category,
      date: date,
      amount: -(rand(5..75).to_f.round(2))
    ) do |t|
      t.payee = misc_payees.sample
    end
    misc_count += 1
  end
end

puts "  Created #{misc_count} miscellaneous transactions"

# Credit card payments: pay each month's balance in full on the 1st of the next month.
# Start from the 1st after start_date (e.g. Dec 1 pays November) through at least March 1 (pays February).
# By March 1 the user has $0 credit card debt carried over.
puts "Creating credit card payments (pay in full at start of each month)..."
payment_count = 0
payment_first_date = start_date + 1.month  # first payment date (e.g. Dec 1 pays November)
payment_end_date = [end_date, Date.new(end_date.year, 3, 1)].max
payment_first_date.upto(payment_end_date) do |date|
  next unless date.day == 1
  prev_month_start = date - 1.month
  prev_month_end = date - 1.day
  total_charges = Transaction
    .where(user: user, account: credit_card)
    .where("date >= ? AND date <= ?", prev_month_start, prev_month_end)
    .where("amount < 0")
    .sum(:amount)
  next if total_charges >= 0
  payment_amount = -total_charges
  [[checking_account, -payment_amount], [credit_card, payment_amount]].each do |acct, amt|
    tx = Transaction.find_or_initialize_by(
      user: user,
      account: acct,
      date: date,
      payee: "Credit Card Payment"
    )
    tx.category = transfers_category
    tx.amount = amt
    tx.save!
  end
  payment_count += 2
end
puts "  Created #{payment_count / 2} credit card payment(s) (#{payment_count} transactions)"

# Apply carryover from previous month to current month now that all transactions exist (previous month has correct spent; balance = allotted - spent becomes next month's allotted).
if current_month != TEMPLATE_MONTH
  prev_bm = budget.budget_months.find_by(month: current_month - 1.month)
  if prev_bm
    CategoryCarryoverService.apply_carryover_to_next_month(prev_bm)
    budget_month.reload
  end
end

# Create goals for each category (except income)
puts "Creating goals..."
goal_specs = [
  { category: groceries_category, goal_type: "needed_for_spending", target_amount: 600.00 },
  { category: utilities_category, goal_type: "needed_for_spending", target_amount: 250.00 },
  { category: subscriptions_category, goal_type: "needed_for_spending", target_amount: 100.00 },
  { category: misc_category, goal_type: "needed_for_spending", target_amount: 300.00 },
]

goal_specs.each do |spec|
  Goal.find_or_create_by!(user: user, category: spec[:category]) do |g|
    g.goal_type = spec[:goal_type]
    g.target_amount = spec[:target_amount]
    g.target_date = nil
  end
end

puts "  Created #{goal_specs.count} goals"

# Ensure a Summary exists for the current budget month (income will be managed by callbacks)
Summary.find_or_create_by!(user: user, budget_month: budget_month) do |s|
  s.income = 0
  s.carryover = 0
  s.available = 0
end

# Recalculate available after allotments
BudgetService.calculate_budget_month_available(budget_month)

# ---------- Backfill previous months: structure carries over from template (Feb 2026) ----------
puts "\nBackfilling previous months (structure from #{TEMPLATE_MONTH.strftime('%B %Y')}, summaries + carryover)..."
NUM_PREVIOUS_MONTHS = 2
# Ensure template has been built (it's the source for all months)
template_budget_month.reload

(NUM_PREVIOUS_MONTHS + 1).times do |i|
  month_start = (Date.current - i.months).beginning_of_month.to_date
  bm = budget.find_or_create_budget_month!(month_start, user)

  # Copy category groups and category_months from template so categories carry over onto this month
  copy_budget_month_structure(template_budget_month, bm, user) unless bm.id == template_budget_month.id
  bm.reload

  # Ensure summary exists and income is set from transactions (BudgetService may have set it when income tx were created)
  summary = Summary.find_or_create_by!(user: user, budget_month: bm) do |s|
    s.income = 0
    s.carryover = 0
    s.available = 0
  end
  # Recompute income for this month from income transactions (in case summary was created before income tx)
  income_in_month = Transaction
    .where(user: user, category: income_category)
    .where("date >= ? AND date < ?", month_start, month_start + 1.month)
    .sum(:amount)
  if income_in_month != summary.income.to_f
    summary.update!(income: income_in_month)
  end

  # Add variety: notes on past months for summary display
  if month_start < current_month
    summary.update!(notes: "Backfilled #{month_start.strftime('%B %Y')} — income and spending from transactions.")
  end

  BudgetService.calculate_budget_month_available(bm)
end

# Apply carryover from the month before the template (e.g. January) to the template (February),
# so February gets January's category balances and January's leftover Ready to assign.
month_before_template = budget.budget_months.find_by(month: TEMPLATE_MONTH - 1.month)
if month_before_template
  CategoryCarryoverService.apply_carryover_to_next_month(month_before_template)
  template_budget_month.reload
end

# Set carryover on current month from previous month's category balances (and ready-to-assign)
prev_budget_month = budget.budget_months.find_by(month: (Date.current - 1.month).beginning_of_month.to_date)
if prev_budget_month
  carryover_amount = CategoryCarryoverService.calculate_carryover_for_month(prev_budget_month)
  current_summary = Summary.find_by(user: user, budget_month: budget_month)
  if current_summary
    current_summary.update!(carryover: carryover_amount)
    BudgetService.calculate_budget_month_available(budget_month)
  end
end

# Create December 2025 with same category groups/structure as Jan–Mar so that month can be viewed
dec_2025 = Date.new(2025, 12, 1)
bm_dec = budget.find_or_create_budget_month!(dec_2025, user)
copy_budget_month_structure(template_budget_month, bm_dec, user) unless bm_dec.id == template_budget_month.id
bm_dec.reload
summary_dec = Summary.find_or_create_by!(user: user, budget_month: bm_dec) do |s|
  s.income = 0
  s.carryover = 0
  s.available = 0
end
income_dec = Transaction
  .where(user: user, category: income_category)
  .where("date >= ? AND date < ?", dec_2025, dec_2025 + 1.month)
  .sum(:amount)
summary_dec.update!(income: income_dec) if income_dec != summary_dec.income.to_f
BudgetService.calculate_budget_month_available(bm_dec)
puts "  December 2025: category groups and categories created (same as template)."

# Create budget months for the rest of the year (March–December); each reflects the previous month
# (e.g. overspent in February stays overspent in March until the user allots more)
puts "\nCreating budget months for rest of year (March–December 2026)..."
year = TEMPLATE_MONTH.year
created_rest = 0
(3..12).each do |month_num|
  target_month = Date.new(year, month_num, 1)
  result = MonthTransitionService.transition_month(budget, target_month: target_month, user: user)
  created_rest += 1 if result[:created]
end
puts "  Created #{created_rest} new month(s); existing months skipped."

# Recalculate account balances
puts "Recalculating account balances..."
checking_account.recalculate_balance!
credit_card.recalculate_balance!
savings_account.recalculate_balance!

puts "\n✅ Mock data created successfully!"
puts "  - Budget: Created (ID: #{budget.id})"
puts "  - Checking Account: #{checking_account.name} (Balance: $#{checking_account.balance.round(2)})"
puts "  - Emergency Fund: #{savings_account.name} (Balance: $#{savings_account.balance.round(2)})"
puts "  - Credit Card: #{credit_card.name} (Balance: $#{credit_card.balance.round(2)})"
puts "  - Total transactions: #{income_count + savings_transfer_count + bill_count + grocery_count + misc_count + payment_count}"
puts "  - Category groups (this month): #{budget_month.category_groups.count}"
puts "  - Category months (this month): #{user.category_months.where(month: current_month).count}"
puts "  - Previous months backfilled: #{NUM_PREVIOUS_MONTHS + 1} (with summaries and carryover)"
puts "  - Rest of year: March–December #{year} (structure and carryover from previous month each time)"
puts "\nYou can now view this data in your frontend app!"
