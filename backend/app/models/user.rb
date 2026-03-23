class User < ApplicationRecord
  # Emails that are demo/seed accounts; password change and reset are disabled for these.
  DEMO_EMAILS = %w[single@example.com family@example.com mother@demo.com test@email.com].freeze

  has_secure_password

  has_many :account_groups
  has_many :accounts
  has_many :categories
  has_many :transactions
  has_many :budgets
  has_many :budget_months
  has_many :category_groups
  has_many :category_months
  has_many :goals
  has_many :summaries

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 12 }, format: {
    with: /\A(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).+\z/,
    message: "must be at least 12 characters and include a number and special character"
  }, if: -> { new_record? || !password.nil? }

  def self.demo_email?(email)
    email.present? && DEMO_EMAILS.include?(email.strip.downcase)
  end

  def demo_user?
    self.class.demo_email?(email)
  end
end

