module DataLab
  module Constants
    # Taux de conversion monétaires (fixes)
    FLEX_TO_USD = 0.0077
    BFT_TO_USD = 0.01
    SM_TO_USD = 0.01

    # Ordre des raretés (fixe)
    RARITY_ORDER = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"].freeze

    # Métriques de base des badges
    BADGE_BASE_METRICS = {
      "Common" => { name: "Rookie", supply: 200_000, floor_price: 7.99, efficiency: 0.1 },
      "Uncommon" => { name: "Initiate", supply: 100_000, floor_price: 28.50, efficiency: 0.205 },
      "Rare" => { name: "Encore", supply: 50_000, floor_price: 82.50, efficiency: 0.420 },
      "Epic" => { name: "Contender", supply: 25_000, floor_price: 410.00, efficiency: 1.292 },
      "Legendary" => { name: "Challenger", supply: 10_000, floor_price: 1000.00, efficiency: 3.974 },
      "Mythic" => { name: "Veteran", supply: 5_000, floor_price: 4000.00, efficiency: 12.219 },
      "Exalted" => { name: "Champion", supply: 1_000, floor_price: 100_000.00, efficiency: 375.74 },
      "Exotic" => { name: "Olympian", supply: 250, floor_price: 55_000.00, efficiency: 154.054 },
      "Transcendent" => { name: "Prodigy", supply: 100, floor_price: 150000.00, efficiency: 631.620 },
      "Unique" => { name: "MVP", supply: 1, floor_price: 500000.00, efficiency: 2589.642 }
    }.freeze

    # BFT par minute par rareté
    BFT_PER_MINUTE_BY_RARITY = {
      "Common" => 10,
      "Uncommon" => 20,
      "Rare" => 30,
      "Epic" => 40,
      "Legendary" => 50,
      "Mythic" => 60,
      "Exalted" => 70,
      "Exotic" => 80,
      "Transcendent" => 90,
      "Unique" => 100
    }.freeze

    # Énergie maximale par rareté
    MAX_ENERGY_BY_RARITY = {
      "Common" => 1,
      "Uncommon" => 2,
      "Rare" => 3,
      "Epic" => 4,
      "Legendary" => 5,
      "Mythic" => 6,
      "Exalted" => 7,
      "Exotic" => 8,
      "Transcendent" => 9,
      "Unique" => 10
    }.freeze

    # Temps de jeu par rareté
    IN_GAME_TIME_BY_RARITY = {
      "Common" => 60,
      "Uncommon" => 120,
      "Rare" => 180,
      "Epic" => 240,
      "Legendary" => 300,
      "Mythic" => 360,
      "Exalted" => 420,
      "Exotic" => 480,
      "Transcendent" => 540,
      "Unique" => 600
    }.freeze

    # Coûts de recharge
    RECHARGE_COSTS = {
      flex: {
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
      }.freeze,
      sm: {
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
      }.freeze
    }.freeze

    # Niveaux maximum des contrats par rareté
    CONTRACT_MAX_LEVEL = {
      "Common" => 10,
      "Uncommon" => 20,
      "Rare" => 30,
      "Epic" => 40,
      "Legendary" => 50,
      "Mythic" => 60,
      "Exalted" => 70,
      "Exotic" => 80,
      "Transcendent" => 90,
      "Unique" => 100
    }.freeze

    # Temps de craft de base et incrément
    BASE_CRAFT_TIME = 120
    CRAFT_TIME_INCREMENT = 60

    # Coûts de level up des contrats
    LEVEL_UP_COSTS = {
      1 => 420,    # Valeur confirmée
      2 => 855,    # Valeur calculée
      3 => 1275,   # Valeur calculée
      4 => 1695,   # Valeur calculée
      5 => 2174,   # Valeur confirmée
      6 => 2632,   # Valeur calculée
      7 => 2940,   # Valeur calculée
      8 => 3300,   # Valeur calculée
      9 => 3750,   # Valeur calculée
      10 => 4545   # Valeur confirmée
    }.freeze

    # Coûts de craft en FLEX par rareté
    FLEX_CRAFT_COSTS = {
      "Common" => 1300,
      "Uncommon" => 290,
      "Rare" => 1400,
      "Epic" => 6300,
      "Legendary" => 25600,
      "Mythic" => 92700,
      "Exalted" => 368192,
      "Exotic" => 750000,
      "Transcendent" => 1000000,
      "Unique" => 1500000
    }.freeze

    # Coûts de craft en SP Marks par rareté
    SP_MARKS_CRAFT_COSTS = {
      "Common" => 0,
      "Uncommon" => 3967,
      "Rare" => 6616,
      "Epic" => 16556,
      "Legendary" => 27618,
      "Mythic" => 28222,
      "Exalted" => 219946,
      "Exotic" => 300000,
      "Transcendent" => 400000,
      "Unique" => 500000
    }.freeze

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

      def calculate_recharge_time(rarity)
        return "8h00" unless rarity && RARITY_ORDER.include?(rarity)

        base_hours = 8
        decrement = 0.25 * RARITY_ORDER.index(rarity)
        hours = base_hours - decrement

        whole_hours = hours.floor
        minutes = ((hours - whole_hours) * 60).round
        format("%dh%02d", whole_hours, minutes)
      end

      def calculate_recharge_cost(rarity)
        return nil unless RARITY_ORDER.include?(rarity)

        flex_cost = RECHARGE_COSTS[:flex][rarity]
        sm_cost = RECHARGE_COSTS[:sm][rarity]

        return nil if flex_cost.nil? || sm_cost.nil?

        {
          flex: flex_cost,
          sm: sm_cost,
          total_usd: (flex_cost * FLEX_TO_USD + sm_cost * BFT_TO_USD).round(2)
        }
      end

      def calculate_slot_roi(badge, slots_count, slot_total_cost, recharge_cost, bft_value_per_max_charge)
        return 0 if badge.nil? || slots_count.nil? || slot_total_cost.nil? ||
                   recharge_cost.nil? || bft_value_per_max_charge.nil? ||
                   bft_value_per_max_charge.zero?

        total_cost = badge.floor_price + recharge_cost
        slots = slots_count + 1

        numerator = slot_total_cost +
                   (total_cost * slots) +
                   ((((total_cost * slots)/bft_value_per_max_charge) - (1 * slots)) * recharge_cost)

        denominator = bft_value_per_max_charge * slots

        (numerator / denominator).round(2)
      end
    end

    # Métriques de craft par rareté
    CRAFT_METRICS = {
      "Common" => {
        supply: 5_000,
        previous_rarity_needed: 0,
        cash_cost: 1,
        bft_tokens: 112,
        sponsor_marks_reward: 26
      },
      "Uncommon" => {
        supply: 2_000,
        previous_rarity_needed: 2,
        cash_cost: 1,
        bft_tokens: 343,
        sponsor_marks_reward: 80
      },
      "Rare" => {
        supply: 1_500,
        previous_rarity_needed: 2,
        cash_cost: 1,
        bft_tokens: 812,
        sponsor_marks_reward: 250
      },
      "Epic" => {
        supply: 750,
        previous_rarity_needed: 2,
        cash_cost: 1500,
        bft_tokens: 812,
        sponsor_marks_reward: 760
      },
      "Legendary" => {
        supply: 500,
        previous_rarity_needed: 2,
        cash_cost: 3000,
        bft_tokens: 2500,
        sponsor_marks_reward: 2300
      },
      "Mythic" => {
        supply: 200,
        previous_rarity_needed: 2,
        cash_cost: 6000,
        bft_tokens: 7692,
        sponsor_marks_reward: 7200
      },
      "Exalted" => {
        supply: 100,
        previous_rarity_needed: 2,
        cash_cost: 12000,
        bft_tokens: 23669,
        sponsor_marks_reward: 3200
      },
      "Exotic" => {
        supply: 50,
        previous_rarity_needed: 2,
        cash_cost: 24000,
        bft_tokens: 39612,
        sponsor_marks_reward: 10000
      },
      "Transcendent" => {
        supply: 25,
        previous_rarity_needed: 2,
        cash_cost: 48000,
        bft_tokens: 224082,
        sponsor_marks_reward: 31400
      },
      "Unique" => {
        supply: 1,
        previous_rarity_needed: 2,
        cash_cost: 96000,
        bft_tokens: 335172,
        sponsor_marks_reward: 97400
      }
    }.freeze
  end
end
