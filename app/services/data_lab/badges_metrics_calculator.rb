module DataLab
  class BadgesMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user)
      @user = user
    end

    def calculate
      badges = load_badges
      {
        badges_metrics: calculate_badges_metrics(badges),
        badges_details: calculate_badges_details(badges)
      }
    end

    private

    def load_badges
      Item.includes(:type, :rarity, :item_farming, :item_recharge, :item_crafting)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .map { |badge| update_badge_supply(badge) }
          .sort_by { |badge| Constants::RARITY_ORDER.index(badge.rarity.name) }
    end

    def update_badge_supply(badge)
      if Constants::BADGE_BASE_METRICS[badge.rarity.name]
        badge.supply = Constants::BADGE_BASE_METRICS[badge.rarity.name][:supply]
      end
      badge
    end

    def calculate_badges_metrics(badges)
      badges.map do |badge|
        next unless valid_badge?(badge)

        metrics_data(badge)
      end.compact
    end

    def metrics_data(badge)
      rarity = badge.rarity.name
      recharge_cost = calculate_recharge_cost(rarity)
      bft_per_minute = calculate_bft_per_minute(badge)
      max_energy = calculate_max_energy(badge)
      bft_value_per_max_charge = calculate_bft_value_per_max_charge(badge)
      recharge_time = calculate_recharge_time(badge)

      {
        "1. rarity": rarity,
        "2. item": Constants::BADGE_BASE_METRICS[rarity][:name] || "Unknown",
        "3. supply": badge.supply || 0,
        "4. floor_price": format_currency(badge.floorPrice),
        "5. efficiency": badge.item_farming&.efficiency || 0,
        "6. ratio": calculate_ratio(badge),
        "7. max_energy": max_energy,
        "8. time_to_charge": recharge_time,
        "9. in_game_time": calculate_in_game_time(badge),
        "10. recharge_cost": format_currency(recharge_cost&.[](:total_usd)),
        "11. cost_per_hour": format_currency(calculate_cost_per_hour(recharge_cost&.[](:total_usd), recharge_time)),
        "12. bft_per_minute": bft_per_minute,
        "13. bft_per_max_charge": calculate_bft_per_max_charge(badge),
        "14. bft_value_per_max_charge": format_currency(bft_value_per_max_charge),
        "15. roi": calculate_roi(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)
      }
    end

    def calculate_badges_details(badges)
      badges.map do |badge|
        next unless valid_badge?(badge)

        details_data(badge)
      end.compact
    end

    def details_data(badge)
      rarity = badge.rarity.name
      recharge_cost = calculate_recharge_cost(rarity)
      bft_value_per_max_charge = calculate_bft_value_per_max_charge(badge)

      {
        "1. rarity": rarity,
        "2. badge_price": format_currency(badge.floorPrice),
        "3. full_recharge_price": format_currency(recharge_cost&.[](:total_usd)),
        "4. total_cost": format_currency(calculate_total_cost(badge, recharge_cost)),
        "5. in_game_minutes": calculate_in_game_minutes(badge),
        "6. bft_per_max_charge": calculate_bft_per_max_charge(badge),
        "7. bft_value": format_currency(bft_value_per_max_charge),
        "8. roi": calculate_roi(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)
      }
    end

    def calculate_total_cost(badge, recharge_cost)
      badge.floorPrice.to_f + (recharge_cost&.[](:total_usd) || 0)
    end

    def calculate_in_game_time(badge)
      "#{calculate_in_game_minutes(badge) / 60}h"
    end

    def calculate_in_game_minutes(badge)
      return 0 unless valid_badge?(badge)
      Constants::IN_GAME_TIME_BY_RARITY[badge.rarity.name] || 0
    end

    def calculate_bft_per_max_charge(badge)
      bft_per_minute = calculate_bft_per_minute(badge)
      max_energy = calculate_max_energy(badge)
      return 0 if bft_per_minute.nil? || max_energy.nil?

      (bft_per_minute * max_energy * 60).round(2)
    end

    def calculate_recharge_cost(rarity)
      flex_cost = Constants::RECHARGE_COSTS[:flex][rarity]
      sm_cost = Constants::RECHARGE_COSTS[:sm][rarity]

      return nil if flex_cost.nil? || sm_cost.nil?

      {
        flex: flex_cost,
        sm: sm_cost,
        total_usd: calculate_total_usd(flex_cost, sm_cost)
      }
    end

    def calculate_total_usd(flex_cost, sm_cost)
      (flex_cost * Constants::FLEX_TO_USD + sm_cost * Constants::BFT_TO_USD).round(2)
    end

    def calculate_bft_per_minute(badge)
      return nil unless valid_badge?(badge)
      Constants::BFT_PER_MINUTE_BY_RARITY[badge.rarity.name]
    end

    def calculate_max_energy(badge)
      return nil unless valid_badge?(badge)
      Constants::MAX_ENERGY_BY_RARITY[badge.rarity.name]
    end

    def calculate_recharge_time(badge)
      return nil unless valid_badge?(badge)
      Constants::Calculator.calculate_recharge_time(badge.rarity.name)
    end

    def calculate_roi(badge, recharge_cost, bft_value_per_max_charge)
      return 0 if invalid_roi_params?(badge, recharge_cost, bft_value_per_max_charge)

      total_cost = badge.floorPrice.to_f + recharge_cost.to_f
      (total_cost / bft_value_per_max_charge).round(2)
    end

    def invalid_roi_params?(badge, recharge_cost, bft_value_per_max_charge)
      badge.nil? || recharge_cost.nil? || bft_value_per_max_charge.nil? || bft_value_per_max_charge.zero?
    end

    def calculate_bft_value_per_max_charge(badge)
      bft_per_max_charge = calculate_bft_per_max_charge(badge)
      return 0 if bft_per_max_charge.nil?

      (bft_per_max_charge * Constants::BFT_TO_USD).round(2)
    end

    def calculate_ratio(badge)
      return 0 unless valid_badge?(badge)
      Constants::RARITY_ORDER.index(badge.rarity.name) + 1
    end

    def calculate_cost_per_hour(recharge_cost, recharge_time)
      return 0 unless recharge_cost && recharge_time

      hours = convert_time_to_minutes(recharge_time) / 60.0
      return 0 if hours.zero?

      (recharge_cost / hours).round(2)
    end

    def valid_badge?(badge)
      badge&.rarity&.name && Constants::RARITY_ORDER.include?(badge.rarity.name)
    end
  end
end
