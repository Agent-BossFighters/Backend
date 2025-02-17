module DataLab
  class SlotsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    # Bonus BFT par slot (en pourcentage)
    BONUS_BFT_PERCENT = {
      1 => 0,    # 0%
      2 => 10,   # 10%
      3 => 20,   # 20%
      4 => 30    # 30%
    }.freeze

    # Bonus BFT total par nombre de slots
    TOTAL_BONUS_BFT_PERCENT = {
      1 => 1.0,   # 1%
      2 => 4.5,   # 4.5%
      3 => 12.0,  # 12%
      4 => 25.0   # 25%
    }.freeze

    # Base values for calculations
    BASE_NORMAL_PART = 100
    BASE_BONUS_PART = 10

    RARITY_ORDER = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"]

    def initialize(user, badge_rarity = "Common")
      @user = user
      @badge_rarity = badge_rarity || "Common"
    end

    def calculate
      slots = Slot.includes(:currency, :game)
      slots_costs = calculate_slots_cost(slots)

      # Calculer le total des coûts de tous les slots
      total_slots_cost = slots.sum(:unlockPrice)
      total_flex = slots.sum(:unlockCurrencyNumber)
      nb_slots = @user.user_slots.count

      # Calculer les ROI avec la formule complète
      bft_value_per_charge = calculate_bft_value_per_charge(@badge_rarity)
      recharge_cost = calculate_recharge_cost(@badge_rarity)

      # Calcul des ROI avec les multiplicateurs
      base_roi = calculate_total_slots_roi(total_slots_cost, nb_slots, recharge_cost&.[](:total_usd), bft_value_per_charge)

      {
        slots_cost: slots_costs,
        unlocked_slots: {
          "1. total_flex": total_flex,
          "2. total_cost": format_currency(total_slots_cost),
          "3. total_bonus_bft": TOTAL_BONUS_BFT_PERCENT[nb_slots] || 0,
          "4. nb_tokens_roi": base_roi,
          "5. nb_charges_roi_1.0": base_roi,
          "6. nb_charges_roi_2.0": (base_roi / 2.0).round(0),
          "7. nb_charges_roi_3.0": (base_roi / 3.0).round(0)
        }
      }
    end

    private

    def calculate_slots_cost(slots)
      slots.map do |slot|
        {
          "1. slot": slot.id,
          "2. nb_flex": slot.unlockCurrencyNumber,
          "3. flex_cost": format_currency(slot.unlockPrice),
          "4. bonus_bft": BONUS_BFT_PERCENT[slot.id] || 0,
          normalPart: calculate_normal_part(slot.id),
          bonusPart: calculate_bonus_part(slot.id)
        }
      end
    end

    def calculate_unlocked_slots(user_slots)
      if user_slots.empty?
        return empty_totals
      end

      unlocked_slot_ids = user_slots.pluck(:slot_id)
      slots = Slot.where(id: unlocked_slot_ids)

      total_flex = slots.sum(:unlockCurrencyNumber)
      total_cost = (total_flex * Constants::FLEX_TO_USD).round(2)
      total_bonus_bft = calculate_total_bonus_bft(slots.count)

      {
        "1. total_flex": total_flex,
        "2. total_cost": format_currency(total_cost),
        "3. total_bonus_bft": total_bonus_bft,
        total_flex: Slot.sum(:unlockCurrencyNumber),
        total_cost: format_currency(Slot.sum(:unlockPrice))
      }
    end

    def empty_totals
      {
        "1. total_flex": 0,
        "2. total_cost": format_currency(0),
        "3. total_bonus_bft": 1.2,
        total_flex: Slot.sum(:unlockCurrencyNumber),
        total_cost: format_currency(Slot.sum(:unlockPrice))
      }
    end

    def calculate_bft_per_minute(rarity)
      return 0 unless RARITY_ORDER.include?(rarity)

      rarity_index = RARITY_ORDER.index(rarity)
      base_value = 15 # Valeur de base pour Common

      # Formule : base_value * (multiplier ^ rarity_index)
      multiplier = rarity_index <= 5 ? 2.5 : 2.0
      (base_value * (multiplier ** rarity_index)).round(0)
    end

    def calculate_max_energy(rarity)
      return 0 unless RARITY_ORDER.include?(rarity)
      RARITY_ORDER.index(rarity) + 1
    end

    def calculate_recharge_cost(rarity)
      return nil unless RARITY_ORDER.include?(rarity)

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
        total_usd: (flex_cost * Constants::FLEX_TO_USD + sm_cost * Constants::BFT_TO_USD).round(2)
      }
    end

    def calculate_bft_value_per_charge(rarity)
      bft_per_minute = Constants::BFT_PER_MINUTE_BY_RARITY[rarity]
      max_energy = Constants::MAX_ENERGY_BY_RARITY[rarity]
      return 0 if bft_per_minute.nil? || max_energy.nil?

      total_bft = bft_per_minute * max_energy * 60
      (total_bft * Constants::BFT_TO_USD).round(2)
    end

    def calculate_bonus_bft_per_slot(slot_id, bft_per_minute)
      return 0 if bft_per_minute.nil?
      # Le bonus augmente de 5% par slot (10%, 15%, 20%, 25%, 30%)
      bonus_percentage = 10 + ((slot_id - 1) * 5)
      (bft_per_minute * (bonus_percentage / 100.0)).round(2)
    end

    def calculate_total_bft_per_charge(slot_id, bft_per_minute, max_energy)
      return 0 if bft_per_minute.nil? || max_energy.nil?
      # BFT total = (BFT de base + bonus) * max_energy * minutes par heure
      base_bft = bft_per_minute
      bonus_bft = calculate_bonus_bft_per_slot(slot_id, bft_per_minute)
      ((base_bft + bonus_bft) * max_energy * 60).round(0)
    end

    def calculate_total_bonus_bft(nb_slots)
      # Le bonus total est de 1 + 0.2 par slot
      1 + (nb_slots * 0.2)
    end

    def calculate_total_slots_roi(slot_total_cost, slots_count, recharge_cost, bft_value_per_charge)
      return 0 if slot_total_cost.nil? || recharge_cost.nil? ||
                 bft_value_per_charge.nil? || bft_value_per_charge.zero?

      total_cost = slot_total_cost + recharge_cost
      slots = slots_count + 1

      numerator = slot_total_cost +
                 (total_cost * slots) +
                 ((((total_cost * slots)/bft_value_per_charge) - slots) * recharge_cost)

      denominator = bft_value_per_charge * slots

      (numerator / denominator).round(0)
    end

    def calculate_normal_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      BASE_NORMAL_PART * slot_id
    end

    def calculate_bonus_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      bonus_percent = BONUS_BFT_PERCENT[slot_id] || 0
      BASE_BONUS_PART * slot_id * bonus_percent
    end

    def calculate_nb_tokens_roi(total_cost)
      return 0 if total_cost.zero?
      (total_cost / 0.01).round(0)  # Assuming 0.01 is the token value
    end

    def calculate_charges_roi(total_cost, multiplier)
      return 0 if total_cost.zero?
      base_charges = case multiplier
        when 1.0 then [5, 10, 19, 29]
        when 2.0 then [3, 5, 10, 15]
        when 3.0 then [2, 4, 7, 10]
        else []
      end

      unlocked_slots = @user.user_slots.count
      base_charges[unlocked_slots - 1] || 0
    end
  end
end
