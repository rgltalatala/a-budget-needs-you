# Dump current budget (and related) data for a user into a seed file.
# Run: rails runner db/dump_seed.rb [user_email]
# Output: db/seeds_dumped.rb (run with: rails runner db/seeds_dumped.rb [user_email])
#
# Use this to save your current allotted amounts and state as the basis for future reseeds.

require_relative "seeds_base"

user_email = ARGV[0] || "test@email.com"
user = User.find_by(email: user_email)

unless user
  puts "User with email #{user_email} not found."
  exit 1
end

budget = user.budgets.first
unless budget
  puts "No budget found for user."
  exit 1
end

# Collect data keyed by natural keys (names, dates) so the seed is idempotent
data = {
  user_email: user.email,
  user_name: user.name,
  budget_months: [],
  categories: [],
  account_groups: [],
  accounts: [],
  summaries: {},
  goals: [],
  transactions: []
}

# Categories (all used by this user)
user.categories.find_each do |c|
  data[:categories] << { name: c.name, is_default: c.is_default }
end

# Account groups and accounts
user.account_groups.order(:sort_order, :created_at).each do |ag|
  data[:account_groups] << { name: ag.name, sort_order: ag.sort_order }
end
user.accounts.each do |a|
  group_name = a.account_group&.name
  data[:accounts] << {
    name: a.name,
    account_type: a.account_type,
    balance: a.balance.to_f,
    account_group_name: group_name
  }
end

# Budget months (ordered by month) with groups, category_months, and summary
budget.budget_months.order(:month).each do |bm|
  month_str = bm.month.to_s
  groups = bm.category_groups.order(:created_at).map do |cg|
    { name: cg.name, is_default: cg.is_default }
  end
  category_months = CategoryMonth
    .joins(:category_group, :category)
    .where(category_groups: { budget_month_id: bm.id }, month: bm.month, user_id: user.id)
    .order("category_groups.created_at", "categories.name")
    .map do |cm|
      {
        category_name: cm.category.name,
        group_name: cm.category_group.name,
        allotted: cm.allotted.to_f,
        spent: cm.spent.to_f,
        balance: cm.balance.to_f
      }
    end
  summary = bm.summaries.first
  data[:budget_months] << {
    month: month_str,
    available: bm.available.to_f,
    groups: groups,
    category_months: category_months,
    summary: summary ? {
      income: summary.income.to_f,
      carryover: summary.carryover.to_f,
      available: summary.available.to_f,
      notes: summary.notes
    } : nil
  }
  data[:summaries][month_str] = data[:budget_months].last[:summary] if summary
end

# Goals (by category name)
user.goals.includes(:category).find_each do |g|
  next unless g.category
  data[:goals] << {
    category_name: g.category.name,
    goal_type: g.goal_type,
    target_amount: g.target_amount&.to_f,
    target_date: g.target_date&.to_s
  }
end

# Transactions (by account name, category name)
user.transactions.order(:date, :created_at).each do |t|
  data[:transactions] << {
    account_name: t.account&.name,
    category_name: t.category&.name,
    date: t.date.to_s,
    amount: t.amount.to_f,
    payee: t.payee
  }
end

# Generate the seed file
out = Rails.root.join("db", "seeds_dumped.rb")
File.open(out, "w") do |f|
  f.puts <<~HEADER
    # Auto-generated seed from current data. Do not edit by hand; regenerate with:
    #   rails runner db/dump_seed.rb [user_email]
    #
    # Run this seed (e.g. after db:reset): rails runner db/seeds_dumped.rb [user_email]
    # Optional user_email defaults to the email used when the dump was created.

    require_relative "seeds_base"

    user_email = ARGV[0] || #{data[:user_email].inspect}
    user = User.find_by(email: user_email)
    unless user
      user = ensure_seed_user(user_email, #{data[:user_name].inspect})
    end

    budget = user.budgets.first_or_create!

    # ----- Categories -----
    categories_by_name = {}
    #{data[:categories].inspect}.each do |c|
      cat = user.categories.find_or_create_by!(name: c[:name]) { |x| x.is_default = c.fetch(:is_default, false) }
      categories_by_name[c[:name]] = cat
    end

    # ----- Account groups and accounts -----
    account_groups_by_name = {}
    #{data[:account_groups].inspect}.each do |ag|
      grp = user.account_groups.find_or_create_by!(name: ag[:name]) { |g| g.sort_order = ag[:sort_order] || 0 }
      account_groups_by_name[ag[:name]] = grp
    end
    accounts_by_name = {}
    #{data[:accounts].inspect}.each do |acc|
      next if acc[:account_group_name].nil?
      grp = account_groups_by_name[acc[:account_group_name]]
      next unless grp
      a = user.accounts.find_or_create_by!(name: acc[:name]) do |x|
        x.account_type = acc[:account_type]
        x.account_group_id = grp.id
      end
      a.update_columns(balance: acc[:balance]) if a.balance.to_f != acc[:balance]
      accounts_by_name[acc[:name]] = a
    end
  HEADER

  # Write data and rest of loader (so we get valid .inspect output and proper ends)
  f.puts
  f.puts "    # ----- Budget months with category groups and category_months -----"
  f.puts "    BUDGET_MONTHS_DATA = #{data[:budget_months].inspect}.freeze"
  f.puts
  f.puts <<~BODY
    BUDGET_MONTHS_DATA.each do |row|
      month_date = Date.parse(row[:month])
      bm = budget.find_or_create_budget_month!(month_date, user)
      bm.update_columns(available: row[:available]) if bm.available.to_f != row[:available]

      row[:groups].each do |g|
        bm.category_groups.find_or_create_by!(user: user, name: g[:name]) { |cg| cg.is_default = g[:is_default] }
      end
      bm.reload

      row[:category_months].each do |cm_row|
        cat = categories_by_name[cm_row[:category_name]]
        cg = bm.category_groups.find_by(name: cm_row[:group_name], user_id: user.id)
        next unless cat && cg
        cm = CategoryMonth.find_or_initialize_by(user: user, category_id: cat.id, month: month_date)
        cm.category_group_id = cg.id
        cm.allotted = cm_row[:allotted]
        cm.spent = cm_row[:spent]
        cm.balance = cm_row[:balance]
        cm.save!
      end

      if row[:summary]
        s = bm.summaries.first || bm.summaries.create!(user: user, income: 0, carryover: 0, available: 0)
        s.update!(
          income: row[:summary][:income],
          carryover: row[:summary][:carryover],
          available: row[:summary][:available],
          notes: row[:summary][:notes]
        )
      end
    end

    # ----- Transactions (clear existing so re-run replaces state) -----
    user.transactions.delete_all
  BODY

  f.puts "    #{data[:transactions].inspect}.each do |tx|"
  f.puts "      acct = accounts_by_name[tx[:account_name]]"
  f.puts "      cat = categories_by_name[tx[:category_name]]"
  f.puts "      next unless acct && cat"
  f.puts "      user.transactions.create!(account: acct, category: cat, date: tx[:date], amount: tx[:amount], payee: tx[:payee].to_s)"
  f.puts "    end"
  f.puts
  f.puts "    # ----- Goals -----"
  f.puts "    user.goals.delete_all"
  f.puts "    #{data[:goals].inspect}.each do |g_row|"
  f.puts "      cat = categories_by_name[g_row[:category_name]]"
  f.puts "      next unless cat"
  f.puts "      user.goals.create!(category: cat, goal_type: g_row[:goal_type], target_amount: g_row[:target_amount], target_date: g_row[:target_date].present? ? Date.parse(g_row[:target_date]) : nil)"
  f.puts "    end"
  f.puts
  f.puts "    user.accounts.find_each(&:recalculate_balance!)"
  f.puts "    budget.budget_months.find_each { |bm| BudgetService.calculate_budget_month_available(bm) }"
  f.puts '    puts "Loaded dumped seed for #{user.email} (#{budget.budget_months.count} budget months, #{user.transactions.count} transactions)."'
end

puts "Dumped seed written to db/seeds_dumped.rb (user: #{user_email}, #{data[:budget_months].size} budget months, #{data[:transactions].size} transactions)."
puts "To load this seed later: rails runner db/seeds_dumped.rb [#{user_email}]"
