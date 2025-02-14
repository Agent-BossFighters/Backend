module DataLab
  module Constants
    # Taux de conversion monétaires (fixes)
    FLEX_TO_USD = 0.0077
    BFT_TO_USD = 0.01
    SM_TO_USD = 0.01

    # Ordre des raretés (fixe)
    RARITY_ORDER = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"]

    # Prix des slots en FLEX
    SLOT_PRICES = {
      1 => 7000,   # Premier slot
      2 => 13000,  # Deuxième slot
      3 => 20000,  # Troisième slot
      4 => 26000   # Quatrième slot
    }.freeze

    # Configuration des cycles de joueurs
    PLAYER_CYCLES = [
      {
        cycleName: "Daily Cycle",
        playerCycleType: 1,
        nbBadge: 3,
        minimumBadgeRarity: "Common",
        nbDateRepeat: 1
      },
      {
        cycleName: "Weekly Cycle",
        playerCycleType: 2,
        nbBadge: 5,
        minimumBadgeRarity: "Uncommon",
        nbDateRepeat: 7
      },
      {
        cycleName: "Monthly Cycle",
        playerCycleType: 3,
        nbBadge: 10,
        minimumBadgeRarity: "Rare",
        nbDateRepeat: 30
      }
    ].freeze

    # Règles de jeu fixes
    MATCHES_PER_CHARGE = 18
    MINUTES_PER_MATCH = 10
    HOURS_PER_ENERGY = 1

    # Efficacité par rareté
    BADGE_EFFICIENCY = {
      "Common" => 0.1,
      "Uncommon" => 0.205,
      "Rare" => 0.420,
      "Epic" => 1.292,
      "Legendary" => 3.974,
      "Mythic" => 12.219,
      "Exalted" => 375.74,
      "Exotic" => 154.054,
      "Transcendent" => 631.620,
      "Unique" => 2589.642
    }

    # Noms des badges (règles de jeu fixes)
    BADGE_NAMES = {
      "Common" => "Rookie",
      "Uncommon" => "Initiate",
      "Rare" => "Encore",
      "Epic" => "Contender",
      "Legendary" => "Challenger",
      "Mythic" => "Veteran",
      "Exalted" => "Champion",
      "Exotic" => "Olympian",
      "Transcendent" => "Prodigy",
      "Unique" => "MVP"
    }

    # Temps de réduction possibles (en pourcentage)
    DISCOUNT_TIMES = [5, 9, 10, 13, 16, 20, 25].freeze

    # Méthodes utilitaires communes
    module Utils
      def format_currency(amount)
        return "???" if amount.nil? || amount == "???"
        "$#{'%.2f' % amount}"
      end

      def convert_time_to_minutes(time_str)
        return "???" if time_str == "???"
        hours, minutes = time_str.match(/(\d+)h(\d+)?/).captures
        hours.to_i * 60 + (minutes || "0").to_i
      end
    end

    # Méthodes de calcul communes
    module Calculator
      extend self

      def calculate_max_energy(rarity)
        return 1 unless rarity && RARITY_ORDER.include?(rarity)
        RARITY_ORDER.index(rarity) + 1
      end

      def calculate_recharge_time(rarity)
        return "8h00" unless rarity && RARITY_ORDER.include?(rarity)
        case rarity
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
        else "5h30"
        end
      end

      def calculate_bft_per_minute(rarity)
        return 0 unless RARITY_ORDER.include?(rarity)
        rarity_index = RARITY_ORDER.index(rarity)
        base_value = 15 # Valeur de base pour Common
        multiplier = rarity_index <= 5 ? 2.5 : 2.0
        (base_value * (multiplier ** rarity_index)).round(0)
      end

      def calculate_recharge_cost(rarity)
        return nil unless RARITY_ORDER.include?(rarity)
        rarity_index = RARITY_ORDER.index(rarity)
        base_flex = 500
        base_sm = 150

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
          total_usd: (flex_cost * FLEX_TO_USD + sm_cost * SM_TO_USD).round(2)
        }
      end

      def calculate_slot_cost(slot_id)
        SLOT_PRICES[slot_id] || 0
      end

      def calculate_slot_roi(badge, slots_count, slot_total_cost, recharge_cost, bft_value_per_max_charge)
        return 0 if badge.nil? || slots_count.nil? || slot_total_cost.nil? || recharge_cost.nil? || bft_value_per_max_charge.nil? || bft_value_per_max_charge.zero?

        total_cost = badge.floor_price + recharge_cost
        slots = slots_count + 1

        numerator = slot_total_cost +
                   (total_cost * slots) +
                   ((((total_cost * slots)/bft_value_per_max_charge) - (1 * slots)) * recharge_cost)

        denominator = bft_value_per_max_charge * slots

        (numerator / denominator).round(2)
      end
    end
  end
end
