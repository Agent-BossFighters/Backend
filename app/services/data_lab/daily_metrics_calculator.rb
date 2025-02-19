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
      {
        matches_count: matches.count,
        fees: {
          total: matches.sum(:totalFee),
          cost: format_currency(matches.sum(:feeCost))
        },
        energy: {
          used: matches.sum(:energyUsed),
          cost: format_currency(matches.sum(:energyCost))
        },
        bft: {
          amount: matches.sum(:totalToken),
          value: format_currency(matches.sum(:tokenValue))
        },
        flex: {
          amount: matches.sum(:totalPremiumCurrency),
          value: format_currency(matches.sum(:premiumCurrencyValue))
        },
        profit: format_currency(matches.sum(:profit))
      }
    end

    def calculate_matches_details
      daily_matches.map do |match|
        {
          id: match.id,
          build: {
            name: match.build,
            slots: match.slots,
            luck_rate: calculate_luck_rate(match),
            map: match.map
          },
          fees: {
            amount: match.totalFee,
            cost: format_currency(match.feeCost)
          },
          badges: format_badges_used(match.badge_used),
          energy: {
            used: match.energyUsed,
            cost: format_currency(match.energyCost)
          },
          rewards: {
            bft: {
              amount: match.totalToken,
              value: format_currency(match.tokenValue)
            },
            flex: {
              amount: match.totalPremiumCurrency,
              value: format_currency(match.premiumCurrencyValue)
            },
            profit: format_currency(match.profit)
          },
          multipliers: {
            bonus: match.bonusMultiplier,
            perks: match.perksMultiplier
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

    def daily_matches
      @daily_matches ||= @user.matches
                             .where("DATE(date) = ?", @date)
                             .includes(badge_used: { nft: { item: :rarity } })
                             .order(date: :asc)
    end
  end
end
