require_relative "seeds_base"

START_DATE = Date.new(2025, 1, 1)
END_DATE   = Date.new(2026, 11, 30)

# =========================
# HELPERS
# =========================

def each_month
  date = START_DATE
  while date <= END_DATE
    yield date
    date = date.next_month
  end
end

def add_txn(user:, account:, category:, amount:, date:, payee:)
  Transaction.create!(
    user_id: user.id,
    account_id: account.id,
    category_id: category.id,
    amount: amount,
    date: date,
    payee: payee
  )
end

def rand_day(month, range = 1..28)
  Date.new(month.year, month.month, rand(range))
end

def create_budget_month(user, month)
  budget = Budget.find_or_create_by!(user_id: user.id)

  BudgetMonth.find_or_create_by!(
    user_id: user.id,
    budget_id: budget.id,
    month: month
  )
end

def create_category_groups_for_month(user, budget_month)
  {
    essentials: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Essentials"
    ),
    lifestyle: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Lifestyle"
    ),
    financial: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Financial"
    )
  }
end

def create_category_groups_for_month(user, budget_month)
  {
    essentials: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Essentials"
    ),
    lifestyle: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Lifestyle"
    ),
    financial: CategoryGroup.create!(
      user_id: user.id,
      budget_month_id: budget_month.id,
      name: "Financial"
    )
  }
end

# =========================
# GENERATORS
# =========================

def generate_paychecks(user:, account:, category:, monthly_income:, month:)
  paycheck = monthly_income / 2

  [1, 15].each do |day|
    add_txn(
      user: user,
      account: account,
      category: category,
      amount: paycheck,
      date: Date.new(month.year, month.month, day),
      payee: "Employer"
    )
  end
end

def generate_subscriptions(user:, account:, subscriptions:, month:)
  subscriptions.each do |sub|
    add_txn(
      user: user,
      account: account,
      category: sub[:category],
      amount: -sub[:amount],
      date: Date.new(month.year, month.month, sub[:day]),
      payee: sub[:name]
    )
  end
end

def generate_weekly_spending(user:, account:, category:, base:, variance:, month:, label:)
  4.times do |i|
    add_txn(
      user: user,
      account: account,
      category: category,
      amount: -(base + rand(variance)),
      date: month.beginning_of_month + (i * 7),
      payee: label
    )
  end
end

def generate_random_events(user:, account:, category:, chance:, min:, max:, month:, label:)
  if rand < chance
    add_txn(
      user: user,
      account: account,
      category: category,
      amount: -(min + rand(max - min)),
      date: rand_day(month),
      payee: label
    )
  end
end

# =========================
# USER 1 (Disciplined)
# =========================

user1 = ensure_seed_user("single@example.com", "Single Male")

ag1 = AccountGroup.create!(user_id: user1.id, name: "Accounts")

checking1 = Account.create!(user_id: user1.id, name: "Checking", account_type: "checking", balance: 3000, account_group_id: ag1.id)
credit1   = Account.create!(user_id: user1.id, name: "Credit Card", account_type: "credit", balance: -4000, account_group_id: ag1.id)

# Categories
rent        = Category.create!(user_id: user1.id, name: "Rent")
groceries   = Category.create!(user_id: user1.id, name: "Groceries")
utilities   = Category.create!(user_id: user1.id, name: "Utilities")
dining      = Category.create!(user_id: user1.id, name: "Dining")
gym         = Category.create!(user_id: user1.id, name: "Gym")
concerts    = Category.create!(user_id: user1.id, name: "Concerts")
subscriptions = Category.create!(user_id: user1.id, name: "Subscriptions")
debt        = Category.create!(user_id: user1.id, name: "Debt")
savings     = Category.create!(user_id: user1.id, name: "Savings")
investing   = Category.create!(user_id: user1.id, name: "Investing")
income      = Category.create!(user_id: user1.id, name: "Income")

each_month do |month|
  generate_paychecks(user: user1, account: checking1, category: income, monthly_income: 5400, month: month)

  # Fixed
  add_txn(user: user1, account: checking1, category: rent, amount: -2000, date: month.beginning_of_month + 1, payee: "Landlord")
  add_txn(user: user1, account: checking1, category: utilities, amount: -150, date: month.beginning_of_month + 3, payee: "Utilities")
  add_txn(user: user1, account: checking1, category: gym, amount: -90, date: month.beginning_of_month + 2, payee: "Climbing Gym")

  # Subscriptions
  generate_subscriptions(
    user: user1,
    account: checking1,
    month: month,
    subscriptions: [
      { name: "Spotify", amount: 11, day: 5, category: subscriptions },
      { name: "Netflix", amount: 16, day: 8, category: subscriptions },
      { name: "Amazon Prime", amount: 15, day: 12, category: subscriptions }
    ]
  )

  # Weekly groceries
  generate_weekly_spending(user: user1, account: checking1, category: groceries, base: 80, variance: 40, month: month, label: "Groceries")

  # Dining
  3.times do
    add_txn(user: user1, account: checking1, category: dining,
      amount: -(20 + rand(50)), date: rand_day(month), payee: "Restaurant")
  end

  # Concerts
  generate_random_events(user: user1, account: credit1, category: concerts, chance: 0.5, min: 60, max: 200, month: month, label: "Concert")

  # Financial discipline
  add_txn(user: user1, account: checking1, category: debt, amount: -400, date: month.beginning_of_month + 10, payee: "Loan")
  add_txn(user: user1, account: checking1, category: savings, amount: -400, date: month.beginning_of_month + 12, payee: "Savings")
  add_txn(user: user1, account: checking1, category: investing, amount: -200, date: month.beginning_of_month + 14, payee: "Brokerage")
end

# =========================
# USER 2 (Family)
# =========================

user2 = ensure_seed_user("family@example.com", "Family")

ag2 = AccountGroup.create!(user_id: user2.id, name: "Accounts")

checking2 = Account.create!(user_id: user2.id, name: "Checking", account_type: "checking", balance: 8000, account_group_id: ag2.id)

# Categories
mortgage   = Category.create!(user_id: user2.id, name: "Mortgage")
groceries2 = Category.create!(user_id: user2.id, name: "Groceries")
utilities2 = Category.create!(user_id: user2.id, name: "Utilities")
tuition    = Category.create!(user_id: user2.id, name: "Tuition")
dining2    = Category.create!(user_id: user2.id, name: "Dining")
family_fun = Category.create!(user_id: user2.id, name: "Family Activities")
subscriptions2 = Category.create!(user_id: user2.id, name: "Subscriptions")
debt2      = Category.create!(user_id: user2.id, name: "Debt")
savings2   = Category.create!(user_id: user2.id, name: "Savings")
income2    = Category.create!(user_id: user2.id, name: "Income")

each_month do |month|
  generate_paychecks(user: user2, account: checking2, category: income2, monthly_income: 7000, month: month)

  # Fixed
  add_txn(user: user2, account: checking2, category: mortgage, amount: -2500, date: month.beginning_of_month + 1, payee: "Mortgage")
  add_txn(user: user2, account: checking2, category: tuition, amount: -1200, date: month.beginning_of_month + 5, payee: "School")
  add_txn(user: user2, account: checking2, category: utilities2, amount: -300, date: month.beginning_of_month + 3, payee: "Utilities")

  # Subscriptions
  generate_subscriptions(
    user: user2,
    account: checking2,
    month: month,
    subscriptions: [
      { name: "Netflix", amount: 16, day: 6, category: subscriptions2 },
      { name: "Disney+", amount: 10, day: 9, category: subscriptions2 }
    ]
  )

  # Groceries (higher spend)
  generate_weekly_spending(user: user2, account: checking2, category: groceries2, base: 150, variance: 100, month: month, label: "Groceries")

  # Dining weekly
  4.times do
    add_txn(user: user2, account: checking2, category: dining2,
      amount: -(60 + rand(60)), date: rand_day(month), payee: "Restaurant")
  end

  # Family activities
  generate_random_events(user: user2, account: checking2, category: family_fun, chance: 0.7, min: 50, max: 200, month: month, label: "Family Fun")

  # Debt
  add_txn(user: user2, account: checking2, category: debt2, amount: -600, date: month.beginning_of_month + 10, payee: "Loan")

  # Leftover savings (variable)
  if rand < 0.6
    add_txn(user: user2, account: checking2, category: savings2,
      amount: -(100 + rand(400)), date: month.beginning_of_month + 20, payee: "Savings")
  end

  # Annual vacation
  if month.month == 7
    add_txn(user: user2, account: checking2, category: family_fun,
      amount: -3000, date: month.beginning_of_month + 15, payee: "Vacation")
  end
end

puts "✅ Realistic behavioral seed complete"