class AccountGroup < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :user_id, presence: true
  validates :name, uniqueness: { scope: :user_id, message: "already exists for this user" }

  has_many :accounts
end
