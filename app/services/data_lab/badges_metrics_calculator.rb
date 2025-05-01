module DataLab
  class BadgesMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user, slots_used = 1, bft_multiplier = 1.0)
      @user = user
      @slots_used = slots_used.to_i.clamp(1, 5)  # Limiter entre 1 et 5 slots
      @bft_multiplier = bft_multiplier.to_f.clamp(0.0, 10.0)  # Limiter le multiplicateur
      @slot = Slot.find_by(id: @slots_used)
      @badges_by_rarity = {}  # Cache pour les badges par rareté

      # Cache pour les taux de devises
      @currency_rates = {
        'FLEX' => Currency.find_by(name: 'FLEX')&.price || 0,
        'Sponsor Marks' => Currency.find_by(name: 'Sponsor Marks')&.price || 0,
        'BFT' => Currency.find_by(name: '$BFT')&.price || 0
      }

      # Cache pour les coûts de recharge
      @recharge_costs = {}
    end

    def calculate
      badges = load_badges
      cache_badges(badges)  # Mettre en cache les badges par rareté
      cache_recharge_costs(badges)  # Mettre en cache les coûts de recharge
      {
        badges_metrics: calculate_badges_metrics(badges),
        badges_details: calculate_badges_details(badges)
      }
    end

    def calculate_recharge_cost(rarity)
      @recharge_costs[rarity] || { flex: 0, sm: 0, total_usd: 0 }
    end

    def load_badges
      Item.includes(:type, :rarity, :item_farming, :item_recharge, :item_crafting)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .order('rarities.id ASC')
    end

    def cache_badges(badges)
      @badges_by_rarity = badges.each_with_object({}) do |badge, hash|
        hash[badge.rarity.name] = badge
      end
    end

    def cache_recharge_costs(badges)
      badges.each do |badge|
        rarity = badge.rarity.name
        @recharge_costs[rarity] = {
          flex: badge.item_recharge&.flex_charge || 0,
          sm: badge.item_recharge&.sponsor_mark_charge || 0
        }
        @recharge_costs[rarity][:total_usd] = calculate_total_usd(
          @recharge_costs[rarity][:flex],
          @recharge_costs[rarity][:sm]
        )
      end
    end

    private

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
      max_energy = badge.item_recharge&.max_energy_recharge
      bft_value_per_max_charge = calculate_bft_value_per_max_charge(badge)
      recharge_time = calculate_recharge_time(badge)
      roi_data = calculate_roi_data(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)

      {
        "1. rarity": rarity,
        "2. item": badge.name,
        "3. supply": badge.supply || 0,
        "4. floor_price": format_currency(badge.floorPrice),
        "5. efficiency": badge.efficiency,
        "6. ratio": calculate_ratio(badge),
        "7. max_energy": max_energy,
        "8. time_to_charge": recharge_time,
        "9. in_game_time": calculate_in_game_time(badge),
        "10. recharge_cost": format_currency(recharge_cost&.[](:total_usd)),
        "11. cost_per_hour": format_currency(calculate_cost_per_hour(recharge_cost&.[](:total_usd), recharge_time)),
        "12. bft_per_minute": bft_per_minute,
        "13. bft_per_max_charge": calculate_bft_per_max_charge(badge),
        "14. bft_value_per_max_charge": format_currency(bft_value_per_max_charge),
        "15. roi": roi_data[:roi],
        "16. nb_charges_roi": roi_data[:charges_needed]
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
      roi_data = calculate_roi_data(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)

      {
        "1. rarity": rarity,
        "2. badge_price": format_currency(badge.floorPrice),
        "3. full_recharge_price": format_currency(recharge_cost&.[](:total_usd)),
        "4. total_cost": format_currency(calculate_total_cost(badge, recharge_cost)),
        "5. in_game_minutes": calculate_in_game_minutes(badge),
        "6. bft_per_max_charge": calculate_bft_per_max_charge(badge),
        "7. bft_value": format_currency(bft_value_per_max_charge),
        "8. roi": roi_data[:roi],
        "9. nb_charges_roi": roi_data[:charges_needed]
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
      badge.item_farming&.in_game_time || 0
    end

    def calculate_bft_per_max_charge(badge)
      return 0 unless valid_badge?(badge)
      return 0 unless badge.item_recharge

      base_bft = calculate_bft_per_minute(badge)
      max_energy = badge.item_recharge.max_energy_recharge

      total_bft = base_bft * max_energy * 60
      total_bft.round(0)
    end

    def calculate_bft_per_minute(badge)
      return 0 unless valid_badge?(badge)
      return 0 unless badge.item_farming

      base_bft = badge.efficiency
      slot_bonus = @slot&.bonus_multiplier || 0
      bft_bonus = @slot&.bonus_bft_percent || 0

      (base_bft * (1 + slot_bonus/100.0) * (1 + bft_bonus/100.0) * @bft_multiplier).round(0)
    end

    def calculate_max_energy(badge)
      return nil unless valid_badge?(badge)
      badge.item_recharge&.max_energy_recharge
    end

    def calculate_recharge_time(badge)
      return nil unless valid_badge?(badge)
      return nil unless badge.item_recharge
      minutes = badge.item_recharge.time_to_charge
      hours = minutes / 60
      remaining_minutes = minutes % 60
      format("%dh%02d", hours, remaining_minutes)
    end

    def calculate_roi_data(badge, recharge_cost, bft_value_per_max_charge)
      return { roi: 0, charges_needed: 0 } if badge.nil?

      # Utiliser des valeurs par défaut si nécessaire
      recharge_cost ||= 0
      bft_value_per_max_charge ||= 0

      # Éviter la division par zéro
      if bft_value_per_max_charge.zero?
        return { roi: 0, charges_needed: 0 }
      end

      # Prix initial du badge
      badge_price = badge.floorPrice.to_f
      total_cost = badge_price + recharge_cost.to_f

      # Calcul du ROI
      charges_needed = total_cost / bft_value_per_max_charge
      roi =  (total_cost+(((total_cost/bft_value_per_max_charge)-1)*recharge_cost))/bft_value_per_max_charge

      {
        roi: roi.round(2),
        charges_needed: charges_needed.round(2)
      }
    end

    def invalid_roi_params?(badge, recharge_cost, bft_value_per_max_charge)
      badge.nil?
    end

    def calculate_bft_value_per_max_charge(badge)
      bft_per_max_charge = calculate_bft_per_max_charge(badge)
      return 0 if bft_per_max_charge.nil?

      (bft_per_max_charge * @currency_rates['BFT']).round(2)
    end

    def calculate_cost_per_hour(recharge_cost, recharge_time)
      return 0 unless recharge_cost && recharge_time

      hours = convert_time_to_minutes(recharge_time) / 60.0
      return 0 if hours.zero?

      (recharge_cost / hours).round(2)
    end

    def valid_badge?(badge)
      badge&.rarity&.name.present?
    end

    def calculate_total_usd(flex_cost, sm_cost)
      (flex_cost * @currency_rates['FLEX'] + sm_cost * @currency_rates['Sponsor Marks']).round(2)
    end

    def calculate_ratio(badge)
      return 1.0 if badge.rarity.name == "Common"

      previous_rarity = find_previous_rarity(badge.rarity)
      return 1.0 unless previous_rarity

      previous_badge = @badges_by_rarity[previous_rarity]
      return 1.0 unless previous_badge

      (badge.efficiency - previous_badge.efficiency).round(2)
    end

    def find_previous_rarity(current_rarity)
      rarity_order = [
        "Common", "Uncommon", "Rare", "Epic", "Legendary",
        "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"
      ]

      current_index = rarity_order.index(current_rarity.name)
      return nil if current_index.nil? || current_index == 0

      rarity_order[current_index - 1]
    end
  end
end
