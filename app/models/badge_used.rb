class BadgeUsed < ApplicationRecord
  belongs_to :match
  belongs_to :nft, foreign_key: 'nftId'
end
