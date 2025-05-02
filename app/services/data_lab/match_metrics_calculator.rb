module DataLab
  class MatchMetricsCalculator
    include Constants::Utils
    include Constants::CurrencyConstants

    def initialize(match)
      @match = match
      @user = match.user
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
      badge_count = @match.badge_used.count
      ((@match.time / Constants::MatchConstants::ENERGY_CONSUMPTION[:ONE_ENERGY_MINUTES]) * badge_count).round(3)
    end

    def calculate_energy_cost
      badge_count = @match.badge_used.count
      return 0 if badge_count.zero?

      energy_cost = 0
      badges_calculator = BadgesMetricsCalculator.new(@user)

      # Charger et mettre en cache les badges et leurs coûts
      badges = badges_calculator.load_badges
      badges_calculator.cache_badges(badges)
      badges_calculator.cache_recharge_costs(badges)

      @match.badge_used.each do |badge_used|
        # Récupérer la rareté du badge
        rarity = badge_used.rarity&.capitalize
        next unless rarity

        # Obtenir le coût de recharge pour cette rareté
        recharge_cost = badges_calculator.calculate_recharge_cost(rarity)
        next unless recharge_cost[:total_usd].positive?

        # Calculer le coût pour ce badge
        energy_per_badge = calculate_energy_used / badge_count

        # Trouver l'item correspondant à la rareté du badge pour obtenir max_energy
        rarity_record = Rarity.find_by(name: rarity.capitalize)
        next unless rarity_record

        item = Item.joins(:type)
                   .where(types: { name: "Badge" }, rarity_id: rarity_record.id)
                   .first
        next unless item&.max_energy&.positive?

        energy_cost += (energy_per_badge * (recharge_cost[:total_usd] / item.max_energy))
      end

      energy_cost.round(2)
      # (calculate_energy_used * Constants::CurrencyConstants.currency_rates[:energy]).round(2)
    end

    def calculate_token_value
      (@match.totalToken.to_f * Constants::CurrencyConstants.currency_rates[:bft]).round(2)
    end

    def calculate_premium_value
      user_rates = Constants::CurrencyConstants.user_currency_rates(@user)
      (@match.totalPremiumCurrency.to_f * user_rates[:flex]).round(2)
    end

    def calculate_luckrate
      return 0 unless @match.badge_used.any?

      @match.badge_used.sum do |badge|
        # Trouver l'item correspondant à la rareté du badge
        rarity = Rarity.find_by(name: badge.rarity.capitalize)
        next 0 unless rarity

        item = Item.joins(:type)
                   .where(types: { name: "Badge" }, rarity_id: rarity.id)
                   .first

        (item&.efficiency || 0) * 100
      end
    end

    def calculate_profit
      bft_value = calculate_token_value
      flex_value = calculate_premium_value
      energy_cost = calculate_energy_cost
      base_profit = bft_value + flex_value - energy_cost

      # Appliquer le bonus BFT s'il existe
      if @match.build.present?
        build = @match.user.user_builds.find_by(buildName: @match.build)
        if build && build.bftBonus
          # Utiliser directement le pourcentage du bonus
          bonus_multiplier = 1 + (build.bftBonus / 100.0)
          return (base_profit).round(2)
        end
      end

      base_profit.round(2)
    end
  end
end
