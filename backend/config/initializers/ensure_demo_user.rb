# Ensure the demo user (test@email.com) exists in development and has mock data so "Sign in as demo" works.
if Rails.env.development?
  Rails.application.config.after_initialize do
    demo_email = "test@email.com"
    user = User.find_or_create_by!(email: demo_email) do |u|
      u.name = "Mock User"
      u.password = u.password_confirmation = "SeedPassword1!"
    end
    next unless user.budgets.empty?

    # Load mock data so demo login has accounts, budgets, transactions, etc.
    original_argv = ARGV.dup
    ARGV.replace([demo_email])
    load Rails.root.join("db", "seeds_mock_data.rb")
    ARGV.replace(original_argv)
  end
end
