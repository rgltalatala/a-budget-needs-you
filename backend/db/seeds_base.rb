# Shared base seed helpers. Required by seeds.rb and optionally by seeds_mock_data.rb.
# Use ensure_seed_user to create or find the canonical seed user.

def ensure_seed_user(email = "test@example.com", name = "Test User")
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    # User model requires password: min 12 chars, at least one number and one special character
    u.password = u.password_confirmation = "SeedPassword1!"
  end
end
