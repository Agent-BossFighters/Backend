class Match < ApplicationRecord
  belongs_to :user
  has_many :badge_used, dependent: :destroy
  has_many :nfts, through: :badge_used

  accepts_nested_attributes_for :badge_used, allow_destroy: true

  # Validations
  validates :build, presence: true
  validates :map, presence: true
  validates :time, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :energyUsed, presence: true, numericality: { greater_than: 0 }
  validates :result, inclusion: { in: %w[win loss] }, allow_nil: true
  validates :totalToken, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :totalPremiumCurrency, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
