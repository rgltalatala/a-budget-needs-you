class Account < ApplicationRecord
  belongs_to :user
  belongs_to :account_group, optional: true

  has_many :transactions

  validates :name, presence: true
  validates :balance, presence: true, numericality: true

  # Recalculate balance from all transactions
  def recalculate_balance!
    self.balance = transactions.sum(:amount)
    save!
  end
end

