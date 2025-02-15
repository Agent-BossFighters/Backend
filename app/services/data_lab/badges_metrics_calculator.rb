module DataLab
  class BadgesMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    RARITY_ORDER = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"]
    BFT_PRICE = 0.01
    FLEX_PRICE = 0.0077

    BADGE_BASE_METRICS = {
      "Common" => {
        name: "Rookie",
        supply: 200_000,
        floor_price: 7.99,
        efficiency: 0.1
      },
      "Uncommon" => {
        name: "Initiate",
        supply: 100_000,
        floor_price: 28.50,
        efficiency: 0.205
      },
      "Rare" => {
        name: "Encore",
        supply: 50_000,
        floor_price: 82.50,
        efficiency: 0.420
      },
      "Epic" => {
        name: "Contender",
        supply: 25_000,
        floor_price: 410.00,
        efficiency: 1.292
      },
      "Legendary" => {
        name: "Challenger",
        supply: 10_000,
        floor_price: 1000.00,
        efficiency: 3.974
      },
      "Mythic" => {
        name: "Veteran",
        supply: 5_000,
        floor_price: 4000.00,
        efficiency: 12.219
      },
      "Exalted" => {
        name: "Champion",
        supply: 1_000,
        floor_price: 100_000.00,
        efficiency: 375.74
      },
      "Exotic" => {
        name: "Olympian",
        supply: 250,
        floor_price: 55_000.00,
        efficiency: 154.054
      },
      "Transcendent" => {
        name: "Prodigy",
        supply: 100,
        floor_price: 150000.00,
        efficiency: 631.620
      },
      "Unique" => {
        name: "MVP",
        supply: 1,
        floor_price: 500000.00,
        efficiency: 2589.642
      }
    }.freeze

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
          .map do |badge|
            # Mettre à jour le supply avec la valeur de BADGE_BASE_METRICS
            if BADGE_BASE_METRICS[badge.rarity.name]
              badge.supply = BADGE_BASE_METRICS[badge.rarity.name][:supply]
            end
            badge
          end
          .sort_by { |badge| RARITY_ORDER.index(badge.rarity.name) }
    end

    def calculate_badges_metrics(badges)
      badges.map do |badge|
        next unless badge&.rarity&.name
        rarity = badge.rarity.name
        recharge_cost = calculate_recharge_cost(rarity)
        bft_per_minute = calculate_bft_per_minute(badge)
        max_energy = calculate_max_energy(badge)
        bft_value_per_max_charge = calculate_bft_value_per_max_charge(badge)

        # Calculate efficiency and ratio
        efficiency = badge.item_farming&.efficiency || "N/A"
        ratio = calculate_ratio(badge)
        cost_per_hour = calculate_cost_per_hour(recharge_cost&.[](:total_usd), calculate_recharge_time(badge))

        {
          "1. rarity": rarity,
          "2. item": Constants::BADGE_NAMES[rarity] || "Unknown",
          "3. supply": badge.supply || 0,
          "4. floor_price": format_currency(badge.floorPrice),
          "5. efficiency": efficiency,
          "6. ratio": ratio,
          "7. max_energy": max_energy,
          "8. time_to_charge": calculate_recharge_time(badge),
          "9. in_game_time": calculate_in_game_time(badge),
          "10. max_charge_cost": format_currency(recharge_cost&.[](:total_usd)),
          "11. cost_per_hour": format_currency(cost_per_hour),
          "12. bft_per_minute": bft_per_minute,
          "13. bft_per_max_charge": calculate_bft_per_max_charge(badge),
          "14. bft_value_per_max_charge": format_currency(bft_value_per_max_charge),
          "15. roi": calculate_roi(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)
        }
      end.compact
    end

    def calculate_badges_details(badges)
      badges.map do |badge|
        rarity = badge.rarity.name
        recharge_cost = calculate_recharge_cost(rarity)
        bft_value_per_max_charge = calculate_bft_value_per_max_charge(badge)

        {
          "1. rarity": rarity,
          "2. badge_price": format_currency(badge.floorPrice),
          "3. full_recharge_price": format_currency(recharge_cost&.[](:total_usd)),
          "4. total_cost": format_currency(badge.floorPrice.to_f + (recharge_cost&.[](:total_usd) || 0)),
          "5. in_game_minutes": calculate_in_game_minutes(badge),
          "6. bft_per_max_charge": calculate_bft_per_max_charge(badge),
          "7. bft_value": format_currency(bft_value_per_max_charge),
          "8. roi": calculate_roi(badge, recharge_cost&.[](:total_usd), bft_value_per_max_charge)
        }
      end
    end

    def calculate_in_game_time(badge)
      minutes = calculate_in_game_minutes(badge)
      "#{minutes / 60}h"
    end

    def calculate_in_game_minutes(badge)
      return 0 unless badge&.rarity&.name && Constants::RARITY_ORDER.include?(badge.rarity.name)

      base_time = case badge.rarity.name
      when "Common" then 60
      when "Uncommon" then 120
      when "Rare" then 180
      when "Epic" then 240
      when "Legendary" then 300
      when "Mythic" then 360
      when "Exalted" then 420
      when "Exotic" then 480
      when "Transcendent" then 540
      when "Unique" then 600
      else 0
      end

      base_time
    end

    def calculate_bft_per_max_charge(badge)
      bft_per_minute = calculate_bft_per_minute(badge)
      max_energy = calculate_max_energy(badge)
      return nil if bft_per_minute.nil? || max_energy.nil?
      bft_per_minute * max_energy * 60
    end

    def calculate_recharge_cost(rarity)
      flex_costs = {
        "Common" => 500,
        "Uncommon" => 1400,
        "Rare" => 2520,
        "Epic" => 4800,
        "Legendary" => 12000,
        "Mythic" => 21000,
        "Exalted" => 9800,
        "Exotic" => 11200,
        "Transcendent" => 12600,
        "Unique" => 14000
      }

      sm_costs = {
        "Common" => 150,
        "Uncommon" => 350,
        "Rare" => 1023,
        "Epic" => 1980,
        "Legendary" => 4065,
        "Mythic" => 8136,
        "Exalted" => nil,
        "Exotic" => nil,
        "Transcendent" => nil,
        "Unique" => nil
      }

      flex_cost = flex_costs[rarity]
      sm_cost = sm_costs[rarity]

      return nil if flex_cost.nil? || sm_cost.nil?

      {
        flex: flex_cost,
        sm: sm_cost,
        total_usd: (flex_cost * FLEX_PRICE + sm_cost * BFT_PRICE).round(2)
      }
    end

    def calculate_bft_per_minute(badge)
      return nil unless badge&.item_farming&.efficiency
      case badge.rarity.name
      when "Common" then 15
      when "Uncommon" then 50
      when "Rare" then 120
      when "Epic" then 350
      when "Legendary" then 1000
      when "Mythic" then 2500
      when "Exalted" then 5000
      when "Exotic" then 10000
      when "Transcendent" then 25000
      when "Unique" then 50000
      else nil
      end
    end

    def calculate_max_energy(badge)
      return nil unless badge&.rarity&.name
      case badge.rarity.name
      when "Common" then 1
      when "Uncommon" then 2
      when "Rare" then 3
      when "Epic" then 4
      when "Legendary" then 5
      when "Mythic" then 6
      when "Exalted" then 7
      when "Exotic" then 8
      when "Transcendent" then 9
      when "Unique" then 10
      else nil
      end
    end

    def calculate_recharge_time(badge)
      return nil unless badge&.rarity&.name && Constants::RARITY_ORDER.include?(badge.rarity.name)
      case badge.rarity.name
      when "Common" then "8h00"
      when "Uncommon" then "7h45"
      when "Rare" then "7h30"
      when "Epic" then "7h15"
      when "Legendary" then "7h00"
      when "Mythic" then "6h45"
      when "Exalted" then "6h30"
      when "Exotic" then "6h15"
      when "Transcendent" then "6h00"
      when "Unique" then "5h45"
      else "8h00"
      end
    end

    def calculate_roi(badge, recharge_cost, bft_value_per_max_charge)
      return nil if badge.nil? || recharge_cost.nil? || bft_value_per_max_charge.nil? || bft_value_per_max_charge.zero?

      total_cost = badge.floorPrice.to_f + recharge_cost.to_f
      return nil if total_cost.zero?

      # ROI = Temps de retour sur investissement en nombre de recharges
      (total_cost / bft_value_per_max_charge).round(2)
    end

    def calculate_bft_value_per_max_charge(badge)
      bft_per_max = calculate_bft_per_max_charge(badge)
      return nil if bft_per_max.nil?
      (bft_per_max * BFT_PRICE).round(2)
    end

    def calculate_ratio(badge)
      return "N/A" unless badge&.rarity&.name
      case badge.rarity.name
      when "Common" then 1
      when "Uncommon" then 2
      when "Rare" then 3
      when "Epic" then 4
      when "Legendary" then 5
      when "Mythic" then 6
      when "Exalted" then 7
      when "Exotic" then 8
      when "Transcendent" then 9
      when "Unique" then 10
      else "N/A"
      end
    end

    def calculate_cost_per_hour(recharge_cost, recharge_time)
      return nil if recharge_cost.nil? || recharge_time.nil?
      hours = convert_time_to_minutes(recharge_time) / 60.0
      return nil if hours.zero?
      (recharge_cost / hours).round(2)
    end

    def format_currency(amount)
      return nil if amount.nil?
      return nil if amount == "???"
      "$#{'%.2f' % amount}"
    end
  end
end
