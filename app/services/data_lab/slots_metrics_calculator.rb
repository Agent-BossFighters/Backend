module DataLab
  class SlotsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user, badge_rarity = "Common")
      @user = user
      @badge_rarity = badge_rarity || "Common"
      @badges = load_badges
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

      # Appliquer le multiplicateur de rareté
      rarity_multiplier = calculate_rarity_multiplier(@badge_rarity)

      {
        slots_cost: slots_costs,
        unlocked_slots: calculate_unlocked_slots_with_rarity(slots, rarity_multiplier, base_roi)
      }
    end

    private

    def load_badges
      query = Item.includes(:type, :rarity)
                 .joins(:rarity)
                 .where(types: { name: 'Badge' })

      if @badge_rarity
        query = query.where(rarities: { name: @badge_rarity })
      end

      query.sort_by { |badge| Constants::BadgeConstants::RARITY_ORDER.index(badge.rarity.name) }
    end

    def calculate_bft_per_minute(rarity)
      return 0 unless Constants::BadgeConstants::RARITY_ORDER.include?(rarity)

      rarity_index = Constants::BadgeConstants::RARITY_ORDER.index(rarity)
      base_value = 15 # Valeur de base pour Common

      # Formule : base_value * (multiplier ^ rarity_index)
      multiplier = rarity_index <= 5 ? 2.5 : 2.0
      (base_value * (multiplier ** rarity_index)).round(0)
    end

    def calculate_max_energy(rarity)
      return 0 unless Constants::BadgeConstants::RARITY_ORDER.include?(rarity)
      Constants::BadgeConstants::RARITY_ORDER.index(rarity) + 1
    end

    def calculate_bft_value_per_charge(rarity)
      bft_per_minute = calculate_bft_per_minute(rarity)
      max_energy = calculate_max_energy(rarity)
      return 0 if bft_per_minute.nil? || max_energy.nil?

      total_bft = bft_per_minute * max_energy * 60
      (total_bft * Constants::CurrencyConstants::CURRENCY_RATES[:bft]).round(2)
    end

    def calculate_recharge_cost(rarity)
      {
        flex: Constants::RechargeConstants::RECHARGE_COSTS[:flex][rarity],
        sm: Constants::RechargeConstants::RECHARGE_COSTS[:sm][rarity]
      }
    end

    def calculate_slots_cost(slots)
      slots.map do |slot|
        {
          "1. slot": slot.id,
          "2. nb_flex": slot.unlockCurrencyNumber,
          "3. flex_cost": format_currency(slot.unlockPrice),
          "4. bonus_bft": Constants::SlotConstants::SLOT_BONUS_MULTIPLIERS[slot.id] || 0,
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
      total_cost = (total_flex * Constants::CurrencyConstants::CURRENCY_RATES[:flex]).round(2)
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

    def calculate_normal_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      Constants::SlotConstants::BASE_NORMAL_PART * slot_id
    end

    def calculate_bonus_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      bonus_percent = Constants::SlotConstants::SLOT_BONUS_MULTIPLIERS[slot_id] || 0
      Constants::SlotConstants::BASE_BONUS_PART * slot_id * bonus_percent
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

    def calculate_rarity_multiplier(rarity)
      case rarity
      when "Common" then 1.0
      when "Uncommon" then 1.5
      when "Rare" then 2.0
      when "Epic" then 2.5
      when "Legendary" then 3.0
      when "Mythic" then 3.5
      when "Exalted" then 4.0
      when "Exotic" then 4.5
      when "Transcendent" then 5.0
      when "Unique" then 5.5
      else 1.0
      end
    end

    def calculate_unlocked_slots_with_rarity(slots, multiplier, base_roi)
      total_flex = slots.sum(:unlockCurrencyNumber)
      total_cost = slots.sum(:unlockPrice)
      nb_slots = @user.user_slots.count

      adjusted_flex = (total_flex * multiplier).round(0)
      adjusted_cost = (total_cost * multiplier).round(2)

      {
        "1. total_flex": adjusted_flex,
        "2. total_cost": format_currency(adjusted_cost),
        "3. total_bonus_bft": Constants::SlotConstants::TOTAL_BONUS_BFT_PERCENT[nb_slots] || 0,
        "4. nb_tokens_roi": (base_roi * multiplier).round(0),
        "5. nb_charges_roi_1.0": (base_roi * multiplier).round(0),
        "6. nb_charges_roi_2.0": ((base_roi * multiplier) / 2.0).round(0),
        "7. nb_charges_roi_3.0": ((base_roi * multiplier) / 3.0).round(0)
      }
    end
  end
end
