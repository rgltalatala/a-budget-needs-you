class Category < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :category_group, optional: true

  has_many :transactions
  has_many :category_months
  has_one :goal

  scope :default_only, -> { where(is_default: true) }
  scope :by_default, ->(default) { where(is_default: default) }

  validates :name, presence: true
end
