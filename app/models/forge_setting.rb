class ForgeSetting < ApplicationRecord
  belongs_to :rarity

  OPERATION_TYPES = %w[merge_digital merge_nft craft_nft].freeze

  validates :operation_type, presence: true, inclusion: { in: OPERATION_TYPES }
  validates :rarity_id, presence: true
end


