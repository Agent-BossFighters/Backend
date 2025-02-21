class BadgeUsed < ApplicationRecord
  belongs_to :match
  belongs_to :nft, foreign_key: 'nftId', optional: true

  validates :slot, presence: true,
                  numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }
  validates :rarity, presence: true,
                    inclusion: { in: %w(rare epic legendary exalted mythic transcendent uncommon) }
end
