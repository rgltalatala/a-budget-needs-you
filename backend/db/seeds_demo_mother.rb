# Demo: Mother in a family of 4, HCOL area, 50/30/20 rule
# Run with: rails runner db/seeds_demo_mother.rb
# Login: mother@demo.com / SeedPassword1!
#
# Income: ~$55k take-home ($75k gross), paid bi-weekly ($2,115/paycheck), 5% EOY bonus (~$2,750 take-home)
# 50% essentials | 20% savings/debt | 30% discretionary

require_relative "seeds_base"

DEMO_MOTHER_EMAIL = "mother@demo.com"
DEMO_MOTHER_NAME = "Sarah (Family of 4)"
PAYCHECK_AMOUNT = 2_115.00
BONUS_TAKE_HOME = 2_750.00
TEMPLATE_MONTH = Date.new(2026, 2, 1).freeze

def iso_month(date)
  date.beginning_of_month.to_date
end

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
      target_cm.allotted = src_cm.allotted
      target_cm.save!
      target_cm.recalculate_spent!
    end
end

user = User.find_by(email: DEMO_MOTHER_EMAIL)
unless user
  user = ensure_seed_user(DEMO_MOTHER_EMAIL, DEMO_MOTHER_NAME)
end

puts "Creating demo data for: #{user.email} (#{DEMO_MOTHER_NAME})..."

# Account groups & accounts
checking_group = AccountGroup.find_or_create_by!(user: user, name: "Checking") { |ag| ag.sort_order = 1 }
savings_group = AccountGroup.find_or_create_by!(user: user, name: "Savings") { |ag| ag.sort_order = 2 }
credit_group = AccountGroup.find_or_create_by!(user: user, name: "Credit Cards") { |ag| ag.sort_order = 3 }

checking = Account.find_or_create_by!(user: user, name: "Main Checking") do |a|
  a.account_type = "checking"
  a.balance = 3_200.00
  a.account_group = checking_group
end

savings_account = Account.find_or_create_by!(user: user, name: "Emergency Fund") do |a|
  a.account_type = "savings"
  a.balance = 5_000.00
  a.account_group = savings_group
end

credit_card = Account.find_or_create_by!(user: user, name: "Credit Card") do |a|
  a.account_type = "credit"
  a.balance = -800.00
  a.account_group = credit_group
end

# Categories
categories = {}
%w[
  Income Mortgage Groceries Utilities Gas Healthcare Childcare
  Subscriptions Insurance Student\ Loans Savings Investments
  Eating\ Out Clothes Miscellaneous Personal\ &\ Kids
].each do |name|
  categories[name] = Category.find_or_create_by!(user: user, name: name) { |c| c.is_default = (name == "Income") }
end

transfers_category = Category.find_or_create_by!(user: user, name: "Credit Card Payment") { |c| c.is_default = false }

# Budget & template month
budget = Budget.find_or_create_by!(user: user)
template_bm = budget.find_or_create_budget_month!(TEMPLATE_MONTH, user)
current_month = iso_month(Date.current)
current_bm = (current_month == TEMPLATE_MONTH) ? template_bm : (budget.find_or_create_budget_month!(current_month, user).tap { |bm| copy_budget_month_structure(template_bm, bm, user) unless bm.id == template_bm.id })
current_bm.reload

# Category groups (50/30/20)
income_grp = CategoryGroup.find_or_create_by!(user: user, budget_month: template_bm, name: "Income") { |cg| cg.is_default = true }
essentials_grp = CategoryGroup.find_or_create_by!(user: user, budget_month: template_bm, name: "Essentials (50%)") { |cg| cg.is_default = true }
savings_debt_grp = CategoryGroup.find_or_create_by!(user: user, budget_month: template_bm, name: "Savings & Debt (20%)") { |cg| cg.is_default = false }
discretionary_grp = CategoryGroup.find_or_create_by!(user: user, budget_month: template_bm, name: "Discretionary (30%)") { |cg| cg.is_default = false }

# Template category_months with allotments (50/30/20 from ~$4,583/mo: 50%=$2,292, 20%=$917, 30%=$1,375)
template_specs = [
  { category: categories["Income"], group: income_grp, allotted: 0 },
  { category: categories["Mortgage"], group: essentials_grp, allotted: 1_100 },
  { category: categories["Groceries"], group: essentials_grp, allotted: 700 },
  { category: categories["Utilities"], group: essentials_grp, allotted: 120 },
  { category: categories["Gas"], group: essentials_grp, allotted: 200 },
  { category: categories["Healthcare"], group: essentials_grp, allotted: 150 },
  { category: categories["Childcare"], group: essentials_grp, allotted: 350 },
  { category: categories["Subscriptions"], group: essentials_grp, allotted: 60 },
  { category: categories["Insurance"], group: essentials_grp, allotted: 92 },
  { category: categories["Student Loans"], group: savings_debt_grp, allotted: 400 },
  { category: categories["Savings"], group: savings_debt_grp, allotted: 350 },
  { category: categories["Investments"], group: savings_debt_grp, allotted: 167 },
  { category: categories["Eating Out"], group: discretionary_grp, allotted: 450 },
  { category: categories["Clothes"], group: discretionary_grp, allotted: 200 },
  { category: categories["Miscellaneous"], group: discretionary_grp, allotted: 400 },
  { category: categories["Personal & Kids"], group: discretionary_grp, allotted: 325 },
]

template_specs.each do |spec|
  cm = CategoryMonth.find_or_initialize_by(user: user, category: spec[:category], month: TEMPLATE_MONTH)
  cm.category_group = spec[:group]
  cm.allotted = spec[:allotted]
  cm.save!
  cm.recalculate_spent!
end

# Ensure current month has same structure and link categories to current month's groups for new transactions
unless current_bm.id == template_bm.id
  copy_budget_month_structure(template_bm, current_bm, user)
  current_bm.reload
end

income_grp_cur = current_bm.category_groups.find_by(name: "Income")
essentials_grp_cur = current_bm.category_groups.find_by(name: "Essentials (50%)")
savings_debt_grp_cur = current_bm.category_groups.find_by(name: "Savings & Debt (20%)")
discretionary_grp_cur = current_bm.category_groups.find_by(name: "Discretionary (30%)")
[categories["Income"] => income_grp_cur, categories["Mortgage"] => essentials_grp_cur, categories["Groceries"] => essentials_grp_cur,
 categories["Utilities"] => essentials_grp_cur, categories["Gas"] => essentials_grp_cur, categories["Healthcare"] => essentials_grp_cur,
 categories["Childcare"] => essentials_grp_cur, categories["Subscriptions"] => essentials_grp_cur, categories["Insurance"] => essentials_grp_cur,
 categories["Student Loans"] => savings_debt_grp_cur, categories["Savings"] => savings_debt_grp_cur, categories["Investments"] => savings_debt_grp_cur,
 categories["Eating Out"] => discretionary_grp_cur, categories["Clothes"] => discretionary_grp_cur, categories["Miscellaneous"] => discretionary_grp_cur,
 categories["Personal & Kids"] => discretionary_grp_cur].each do |cat, grp|
  cat.update!(category_group: grp) if grp && cat.category_group_id != grp.id
end

# Income: bi-weekly paychecks + EOY bonus
puts "Creating income (bi-weekly $#{PAYCHECK_AMOUNT} + Dec bonus $#{BONUS_TAKE_HOME})..."
start_date = 3.months.ago.beginning_of_month.to_date
end_date = Date.current
first_friday = start_date.beginning_of_week(:friday)
first_friday += 7.days if first_friday < start_date
payday = first_friday
income_count = 0
while payday <= end_date
  Transaction.find_or_create_by!(user: user, account: checking, category: categories["Income"], date: payday, amount: PAYCHECK_AMOUNT) do |t| t.payee = "Employer - Payroll" end
  income_count += 1
  payday += 14.days
end
# December bonus (one payment in Dec)
dec_bonus_date = Date.new(end_date.year, 12, 15)
if dec_bonus_date <= end_date && dec_bonus_date >= start_date
  Transaction.find_or_create_by!(user: user, account: checking, category: categories["Income"], date: dec_bonus_date, amount: BONUS_TAKE_HOME) do |t| t.payee = "Employer - Year-End Bonus (5%)" end
  income_count += 1
end
puts "  #{income_count} income transactions"

# Recurring essentials (monthly)
puts "Creating recurring expenses..."
recurring = [
  { payee: "Mortgage", amount: -1_100, category: categories["Mortgage"] },
  { payee: "Electric & Gas Co", amount: -85, category: categories["Utilities"] },
  { payee: "Internet", amount: -65, category: categories["Utilities"] },
  { payee: "Health Insurance", amount: -150, category: categories["Healthcare"] },
  { payee: "Daycare (2 kids)", amount: -350, category: categories["Childcare"] },
  { payee: "Netflix", amount: -15.99, category: categories["Subscriptions"] },
  { payee: "Spotify", amount: -9.99, category: categories["Subscriptions"] },
  { payee: "Phone", amount: -45, category: categories["Subscriptions"] },
  { payee: "Car & Home Insurance", amount: -92, category: categories["Insurance"] },
  { payee: "Student Loan", amount: -400, category: categories["Student Loans"] },
  { payee: "Savings Transfer", amount: -350, category: categories["Savings"] },
  { payee: "Investment Transfer", amount: -167, category: categories["Investments"] },
]
recurring_count = 0
start_date.upto(end_date) do |date|
  next unless date.day == 1
  recurring.each do |r|
    Transaction.find_or_create_by!(user: user, account: checking, category: r[:category], date: date, amount: r[:amount]) { |t| t.payee = r[:payee] }
    recurring_count += 1
  end
end
puts "  #{recurring_count} recurring transactions"

# Groceries (~$1,500/mo for family of 4) - weekly-ish
grocery_stores = ["Whole Foods", "Trader Joe's", "Costco", "Safeway", "Target"]
start_date.upto(end_date) do |date|
  next unless date.saturday? || date.sunday?
  next if rand < 0.25
  amt = -(rand(80..220).to_f.round(2))
  Transaction.find_or_create_by!(user: user, account: credit_card, category: categories["Groceries"], date: date, amount: amt) { |t| t.payee = grocery_stores.sample }
end

# Gas (~$200/mo)
start_date.upto(end_date) do |date|
  next unless date.wday == 0 && rand < 0.6
  Transaction.find_or_create_by!(user: user, account: credit_card, category: categories["Gas"], date: date, amount: -(rand(45..65).to_f.round(2))) { |t| t.payee = "Gas Station" }
end

# Eating out (~$500/mo)
start_date.upto(end_date) do |date|
  next if rand < 0.7
  Transaction.find_or_create_by!(user: user, account: credit_card, category: categories["Eating Out"], date: date, amount: -(rand(25..85).to_f.round(2))) { |t| t.payee = ["Chipotle", "Pizza", "Family Restaurant", "Coffee Shop"].sample }
end

# Clothes, Miscellaneous, Personal & Kids (discretionary)
start_date.upto(end_date) do |date|
  next if rand < 0.85
  cat = [categories["Clothes"], categories["Miscellaneous"], categories["Personal & Kids"]].sample
  payees = { "Clothes" => ["Target", "Old Navy", "Amazon"], "Miscellaneous" => ["Amazon", "CVS", "Starbucks"], "Personal & Kids" => ["Kids Activities", "Haircut", "Pharmacy"] }
  payee = payees[cat.name].sample
  Transaction.find_or_create_by!(user: user, account: credit_card, category: cat, date: date, amount: -(rand(15..120).to_f.round(2))) { |t| t.payee = payee }
end

# Healthcare (copays, etc.)
start_date.upto(end_date) do |date|
  next if rand < 0.95
  Transaction.find_or_create_by!(user: user, account: checking, category: categories["Healthcare"], date: date, amount: -(rand(20..75).to_f.round(2))) { |t| t.payee = "Doctor / Pharmacy" }
end

# Credit card payments (pay in full on 1st of next month)
payment_date = start_date + 1.month
payment_end = [end_date, end_date.end_of_year].max
while payment_date <= payment_end
  if payment_date.day == 1
    prev_start = payment_date - 1.month
    prev_end = payment_date - 1.day
    total_charges = Transaction.where(user: user, account: credit_card).where("date >= ? AND date <= ?", prev_start, prev_end).where("amount < 0").sum(:amount)
    if total_charges < 0
      payment_amt = -total_charges
      [[checking, -payment_amt], [credit_card, payment_amt]].each do |acct, amt|
        tx = Transaction.find_or_initialize_by(user: user, account: acct, date: payment_date, payee: "Credit Card Payment")
        tx.category = transfers_category
        tx.amount = amt
        tx.save!
      end
    end
  end
  payment_date = payment_date.advance(months: 1)
end

# Carryover from previous month to current
if current_month != TEMPLATE_MONTH
  prev_bm = budget.budget_months.find_by(month: current_month - 1.month)
  CategoryCarryoverService.apply_carryover_to_next_month(prev_bm) if prev_bm
  current_bm.reload
end

# Goals (examples)
[
  [categories["Groceries"], "needed_for_spending", 700],
  [categories["Mortgage"], "needed_for_spending", 1_100],
  [categories["Student Loans"], "needed_for_spending", 400],
  [categories["Eating Out"], "needed_for_spending", 450],
].each do |cat, goal_type, target|
  Goal.find_or_create_by!(user: user, category: cat) do |g|
    g.goal_type = goal_type
    g.target_amount = target
    g.target_date = nil
  end
end

# Summary for current month
Summary.find_or_create_by!(user: user, budget_month: current_bm) do |s|
  s.income = 0
  s.carryover = 0
  s.available = 0
end
BudgetService.calculate_budget_month_available(current_bm)
income_in_month = Transaction.where(user: user, category: categories["Income"]).where("date >= ? AND date < ?", current_month, current_month + 1.month).sum(:amount)
Summary.find_by(user: user, budget_month: current_bm)&.update!(income: income_in_month)
BudgetService.calculate_budget_month_available(current_bm)

# Backfill previous months
puts "Backfilling previous months..."
[2, 1, 0].each do |i|
  month_start = (Date.current - i.months).beginning_of_month.to_date
  bm = budget.find_or_create_budget_month!(month_start, user)
  copy_budget_month_structure(template_bm, bm, user) unless bm.id == template_bm.id
  bm.reload
  summary = Summary.find_or_create_by!(user: user, budget_month: bm) { |s| s.income = 0; s.carryover = 0; s.available = 0 }
  income_in_month = Transaction.where(user: user, category: categories["Income"]).where("date >= ? AND date < ?", month_start, month_start + 1.month).sum(:amount)
  summary.update!(income: income_in_month) if income_in_month != summary.income.to_f
  BudgetService.calculate_budget_month_available(bm)
end

# Carryover into template and current
month_before_template = budget.budget_months.find_by(month: TEMPLATE_MONTH - 1.month)
CategoryCarryoverService.apply_carryover_to_next_month(month_before_template) if month_before_template
template_bm.reload if month_before_template
prev_bm = budget.budget_months.find_by(month: (Date.current - 1.month).beginning_of_month.to_date)
if prev_bm
  carryover_amt = CategoryCarryoverService.calculate_carryover_for_month(prev_bm)
  Summary.find_by(user: user, budget_month: current_bm)&.update!(carryover: carryover_amt)
  BudgetService.calculate_budget_month_available(current_bm)
end

# December of previous year + rest of current year
dec_prev = Date.new(Date.current.year - 1, 12, 1)
bm_dec = budget.find_or_create_budget_month!(dec_prev, user)
copy_budget_month_structure(template_bm, bm_dec, user) unless bm_dec.id == template_bm.id
bm_dec.reload
summary_dec = Summary.find_or_create_by!(user: user, budget_month: bm_dec) { |s| s.income = 0; s.carryover = 0; s.available = 0 }
income_dec = Transaction.where(user: user, category: categories["Income"]).where("date >= ? AND date < ?", dec_prev, dec_prev + 1.month).sum(:amount)
summary_dec.update!(income: income_dec) if income_dec != summary_dec.income.to_f
BudgetService.calculate_budget_month_available(bm_dec)

yr = TEMPLATE_MONTH.year
(3..12).each { |m| MonthTransitionService.transition_month(budget, target_month: Date.new(yr, m, 1), user: user) }

# Recalculate account balances
checking.recalculate_balance!
credit_card.recalculate_balance!
savings_account.recalculate_balance!

puts "\n✅ Demo mother created successfully!"
puts "  Login: #{DEMO_MOTHER_EMAIL} / SeedPassword1!"
puts "  Budget: 50% Essentials | 20% Savings & Debt | 30% Discretionary"
puts "  Income: bi-weekly $#{PAYCHECK_AMOUNT} + EOY bonus $#{BONUS_TAKE_HOME}"
puts "  Accounts: Checking, Emergency Fund, Credit Card"
puts "  Categories: Mortgage, Groceries (~$1,500), Eating Out (~$500), Student Loans ($15k), Savings, Investments, etc."
