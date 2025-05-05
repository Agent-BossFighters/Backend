class ContractLevelCost < ApplicationRecord
  validates :level, presence: true, uniqueness: true
  validates :flex_cost, presence: true
  validates :sponsor_mark_cost, presence: true
end
