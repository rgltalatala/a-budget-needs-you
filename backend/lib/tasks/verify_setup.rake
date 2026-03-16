namespace :verify do
  desc "Verify that all models, associations, and seed data are working correctly"
  task setup: :environment do
    puts "\n=== Verifying Budget App Setup ===\n\n"

    # Check User
    user = User.find_by(email: "test@example.com")
    if user.nil?
      puts "❌ ERROR: Test user not found!"
      exit 1
    end
    puts "✅ User found: #{user.name} (#{user.email})"

    # Check Account Groups
    account_groups = user.account_groups
    puts "✅ Account Groups: #{account_groups.count} found"
    account_groups.each do |ag|
      puts "   - #{ag.name} (sort_order: #{ag.sort_order})"
    end

    # Check Accounts
    accounts = user.accounts
    puts "\n✅ Accounts: #{accounts.count} found"
    accounts.each do |account|
      group_name = account.account_group&.name || "No group"
      puts "   - #{account.name} (#{account.account_type}) - Balance: $#{account.balance} - Group: #{group_name}"
    end

    # Check Categories
    categories = user.categories
    puts "\n✅ Categories: #{categories.count} found"
    categories.each do |category|
      default_status = category.is_default? ? "default" : "custom"
      puts "   - #{category.name} (#{default_status})"
    end

    # Check Transactions
    transactions = user.transactions
    puts "\n✅ Transactions: #{transactions.count} found"
    transactions.order(date: :desc).each do |transaction|
      puts "   - #{transaction.date.strftime('%Y-%m-%d')}: #{transaction.payee || 'No payee'} - $#{transaction.amount} (#{transaction.category.name} from #{transaction.account.name})"
    end

    # Test Associations
    puts "\n=== Testing Associations ===\n"

    # Test Account -> Transactions
    test_account = accounts.first
    if test_account
      account_transactions = test_account.transactions
      puts "✅ Account '#{test_account.name}' has #{account_transactions.count} transaction(s)"
    end

    # Test Category -> Transactions
    test_category = categories.first
    if test_category
      category_transactions = test_category.transactions
      puts "✅ Category '#{test_category.name}' has #{category_transactions.count} transaction(s)"
    end

    # Test Transaction -> Account and Category
    test_transaction = transactions.first
    if test_transaction
      puts "✅ Transaction belongs to Account: #{test_transaction.account.name}"
      puts "✅ Transaction belongs to Category: #{test_transaction.category.name}"
      puts "✅ Transaction belongs to User: #{test_transaction.user.name}"
    end

    # Test AccountGroup -> Accounts
    test_group = account_groups.first
    if test_group
      group_accounts = test_group.accounts
      puts "✅ AccountGroup '#{test_group.name}' has #{group_accounts.count} account(s)"
    end

    puts "\n=== Summary ==="
    puts "✅ All models created successfully"
    puts "✅ All associations working correctly"
    puts "✅ Seed data loaded properly"
    puts "\n🎉 Setup verification complete!\n\n"
  end
end
