class Match < ApplicationRecord
  belongs_to :user
  has_many :badge_used, dependent: :destroy
  has_many :nfts, through: :badge_used

  accepts_nested_attributes_for :badge_used, allow_destroy: true

  # Callbacks
  before_validation :normalize_map
  before_validation :calculate_energy_used
  before_save :calculate_values
  before_update :reset_luckrate

  # Validations essentielles
  validates :build, presence: true
  validates :map, presence: true, inclusion: { in: %w[toxic_river award radiation_rift] }
  validates :time, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :energyUsed, presence: true, numericality: { greater_than: 0 }
  validates :result, inclusion: { in: %w[win loss draw] }, allow_nil: true
  validates :totalToken, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :totalPremiumCurrency, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  private

  def normalize_map
    self.map = map.gsub(" ", "_") if map.present?
  end

  def calculate_energy_used
    # Recalculer energyUsed si le temps a changé ou si energyUsed est nil
    if time.present? && (energyUsed.nil? || time_changed?)
      self.energyUsed = energyUsed.to_f
    end
  end

  def calculate_values
    # Valeurs par défaut
    self.energyCost = (energyUsed.to_f * 1.49).round(2)
    self.tokenValue = ((totalToken || 0) * 0.01).round(2)
    self.premiumCurrencyValue = ((totalPremiumCurrency || 0) * 0.00744).round(2)
    self.profit = (tokenValue + premiumCurrencyValue - energyCost).round(2)

    # Calcul du luckrate basé sur les badges
    self.luckrate = calculate_luckrate
  end

  def calculate_luckrate
    return 0 if badge_used.empty?

    badge_used.sum do |badge|
      # Trouver l'item correspondant à la rareté du badge
      item = Item.joins(:rarity)
                 .where(rarities: { name: badge.rarity }, types: { name: "Badge" })
                 .first

      item&.efficiency || 0
    end
  end

  def reset_luckrate
    self.luckrate = 0
  end
end
