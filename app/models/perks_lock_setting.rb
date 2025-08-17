class PerksLockSetting < ApplicationRecord
  belongs_to :rarity
  validates :rarity_id, presence: true
end


