module DataLab
  class MatchMetricsCalculator
    include Constants::Utils
    include Constants::CurrencyConstants

    def initialize(match)
      @match = match
    end

    def calculate
      {
        energyUsed: calculate_energy_used,
        energyCost: calculate_energy_cost,
        tokenValue: calculate_token_value,
        premiumValue: calculate_premium_value,
        luckrate: calculate_luckrate,
        profit: calculate_profit
      }
    end

    private

    def calculate_energy_used
      return 0 unless @match.time
      (@match.time * Constants::MatchConstants::ENERGY_CONSUMPTION[:RATE_PER_MINUTE]).round(2)
    end

    def calculate_energy_cost
      (calculate_energy_used * CURRENCY_RATES[:energy]).round(2)
    end

    def calculate_token_value
      (@match.totalToken.to_f * CURRENCY_RATES[:bft]).round(2)
    end

    def calculate_premium_value
      (@match.totalPremiumCurrency.to_f * CURRENCY_RATES[:flex]).round(2)
    end

    def calculate_luckrate
      return 0 unless @match.badge_used.any?

      @match.badge_used.sum do |badge|
        Constants::MatchConstants::LUCK_RATES[badge.rarity.downcase] || 0
      end
    end

    def calculate_profit
      bft_value = calculate_token_value
      flex_value = calculate_premium_value
      energy_cost = calculate_energy_cost
      base_profit = bft_value + flex_value - energy_cost

      bonus_multiplier = @match.bonusMultiplier || 1.0
      perks_multiplier = @match.perksMultiplier || 1.0

      (base_profit * bonus_multiplier * perks_multiplier).round(2)
    end
  end
end
