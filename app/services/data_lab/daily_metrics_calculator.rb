module DataLab
  class DailyMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user, date)
      @user = user
      @date = date
    end

    def calculate
      {
        summary: calculate_daily_summary,
        matches: calculate_matches_details
      }
    end

    private

    def calculate_daily_summary
      matches = daily_matches
      total_profit = matches.sum do |match|
        base_profit = (match.totalToken.to_f * match.tokenValue.to_f) +
                     (match.totalPremiumCurrency.to_f * match.premiumCurrencyValue.to_f) -
                     (match.energyUsed.to_f * match.energyCost.to_f)

        # Appliquer les multiplicateurs
        base_profit * (match.bonusMultiplier || 1.0) * (match.perksMultiplier || 1.0)
      end

      {
        matches_count: matches.count,
        energy: {
          used: matches.sum(:energyUsed),
          cost: format_currency(matches.sum { |m| m.energyUsed.to_f * m.energyCost.to_f })
        },
        bft: {
          amount: matches.sum(:totalToken),
          value: format_currency(matches.sum { |m| m.totalToken.to_f * m.tokenValue.to_f })
        },
        flex: {
          amount: matches.sum(:totalPremiumCurrency),
          value: format_currency(matches.sum { |m| m.totalPremiumCurrency.to_f * m.premiumCurrencyValue.to_f })
        },
        profit: format_currency(total_profit)
      }
    end

    def calculate_matches_details
      daily_matches.map do |match|
        user_build = @user.user_builds.find_by(buildName: match.build)
        badges_bonus = calculate_badges_bonus(match.badge_used)
        slots_bonus = calculate_slots_bonus(@user.user_slots)

        {
          id: match.id,
          build: {
            name: match.build,
            luck_rate: calculate_luck_rate(match),
            map: match.map
          },
          slots: {
            count: @user.user_slots.count,
            bonus: slots_bonus
          },
          badges: format_badges_used(match.badge_used),
          energy: {
            used: match.energyUsed || 0,
            cost: format_currency(match.energyCost || 0)
          },
          rewards: {
            bft: {
              amount: match.totalToken || 0,
              value: format_currency(match.tokenValue || 0)
            },
            flex: {
              amount: match.totalPremiumCurrency || 0,
              value: format_currency(match.premiumCurrencyValue || 0)
            },
            profit: format_currency(calculate_total_profit(match, badges_bonus, slots_bonus, user_build))
          },
          multipliers: {
            bonus: match.bonusMultiplier || 1.0,
            perks: match.perksMultiplier || 1.0
          },
          time: match.time
        }
      end
    end

    def calculate_luck_rate(match)
      match.badge_used
           .includes(nft: { item: :rarity })
           .sum { |badge| calculate_badge_luck_rate(badge.nft.item.rarity.name) }
    end

    def calculate_badge_luck_rate(rarity)
      return 0 if rarity == 'Select'

      rarity_index = Constants::BadgeConstants::RARITY_ORDER.index(rarity)
      return 0 unless rarity_index

      base = 100
      multiplier = case rarity_index
                  when 0 then 1    # Common
                  when 1 then 2.05 # Uncommon
                  when 2 then 4.2  # Rare
                  when 3 then 12.92 # Epic
                  when 4 then 39.74 # Legendary
                  when 5 then 122.19 # Mythic
                  when 6 then 375.74 # Exalted
                  else 0
                  end

      (base * multiplier).round(0)
    end

    def format_badges_used(badges)
      badges.includes(nft: { item: :rarity }).map do |badge_used|
        rarity = badge_used.nft.item.rarity.name
        {
          nft_id: badge_used.nftId,
          rarity: rarity,
          luck_rate: calculate_badge_luck_rate(rarity)
        }
      end
    end

    def calculate_badges_bonus(badges)
      badges.includes(nft: { item: :rarity }).sum do |badge|
        rarity = badge.nft.item.rarity.name
        calculate_badge_luck_rate(rarity) / 100.0  # Convertir le taux de chance en multiplicateur
      end
    end

    def calculate_slots_bonus(user_slots)
      # À adapter selon votre logique de bonus des slots
      user_slots.count * 0.1  # Par exemple, chaque slot donne 10% de bonus
    end

    def calculate_total_profit(match, badges_bonus, slots_bonus, user_build)
      # Calcul du profit de base à partir des récompenses et des coûts
      base_rewards = ((match.totalToken || 0).to_f * (match.tokenValue || 0).to_f) +
                    ((match.totalPremiumCurrency || 0).to_f * (match.premiumCurrencyValue || 0).to_f)
      base_costs = (match.energyUsed || 0).to_f * (match.energyCost || 0).to_f
      base_profit = base_rewards - base_costs

      # Application des multiplicateurs
      build_multiplier = (user_build&.bonusMultiplier || 1.0) * (user_build&.perksMultiplier || 1.0)

      # Application des bonus dans l'ordre :
      # 1. Bonus des badges
      # 2. Bonus des slots
      # 3. Multiplicateurs du build
      total_profit = base_profit * (1 + badges_bonus) * (1 + slots_bonus) * build_multiplier

      total_profit.round(2)
    end

    def daily_matches
      @daily_matches ||= @user.matches
                             .where("DATE(matches.created_at) = ?", @date)
                             .includes(badge_used: { nft: { item: :rarity } })
                             .order(created_at: :asc)
    end
  end
end
