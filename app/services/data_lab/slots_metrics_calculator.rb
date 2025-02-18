module DataLab
  class SlotsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user)
      @user = user
      @badges = load_badges
    end

    def calculate
      @badges.map do |badge|
        rarity = badge.rarity.name
        recharge_cost = calculate_recharge_cost(rarity)
        next unless recharge_cost

        bft_per_minute = calculate_bft_per_minute(rarity)
        max_energy = calculate_max_energy(rarity)

        slots_data = (1..5).map do |slot_number|
          bft_value = calculate_bft_value_per_charge(bft_per_minute, max_energy, slot_number)
          roi_data = calculate_roi_data(bft_value, recharge_cost)

          {
            slot: slot_number,
            bft_value: bft_value.round(2),
            roi_flex: roi_data[:flex],
            roi_sm: roi_data[:sm],
            nb_tokens_roi: calculate_nb_tokens_roi(bft_value)
          }
        end

        {
          rarity: rarity,
          slots: slots_data
        }
      end.compact
    end

    private

    def load_badges
      Item.includes(:type, :rarity)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .sort_by { |badge| Constants::RARITY_ORDER.index(badge.rarity.name) }
    end

    def calculate_bft_per_minute(rarity)
      base_metrics = Constants::BADGE_BASE_METRICS[rarity]
      base_metrics[:bft_per_minute]
    end

    def calculate_max_energy(rarity)
      base_metrics = Constants::BADGE_BASE_METRICS[rarity]
      base_metrics[:max_energy]
    end

    def calculate_bft_value_per_charge(bft_per_minute, max_energy, slot_number)
      normal_part = Constants::BASE_NORMAL_PART
      bonus_part = Constants::BASE_BONUS_PART * Constants::SLOT_BONUS_MULTIPLIERS[slot_number]

      bft_per_minute * max_energy * (normal_part + bonus_part) / 100.0
    end

    def calculate_recharge_cost(rarity)
      {
        flex: Constants::RECHARGE_COSTS[:flex][rarity],
        sm: Constants::RECHARGE_COSTS[:sm][rarity]
      }
    end

    def calculate_roi_data(bft_value, recharge_cost)
      return { flex: nil, sm: nil } if invalid_roi_params?(bft_value, recharge_cost)

      {
        flex: calculate_roi(bft_value, recharge_cost[:flex], :flex),
        sm: calculate_roi(bft_value, recharge_cost[:sm], :sm)
      }
    end

    def invalid_roi_params?(bft_value, recharge_cost)
      bft_value.nil? || bft_value.zero? || recharge_cost.nil?
    end

    def calculate_roi(bft_value, recharge_cost, currency_type)
      return nil if recharge_cost.nil?

      bft_value_usd = bft_value * Constants::CURRENCY_RATES[:bft]
      recharge_cost_usd = recharge_cost * Constants::CURRENCY_RATES[currency_type]

      ((bft_value_usd / recharge_cost_usd) * 100).round(2)
    end

    def calculate_nb_tokens_roi(bft_value)
      return nil if bft_value.nil? || bft_value.zero?

      (bft_value * Constants::CURRENCY_RATES[:bft]).round(2)
    end

    def calculate_slots_cost(slots)
      slots.map do |slot|
        {
          "1. slot": slot.id,
          "2. nb_flex": slot.unlockCurrencyNumber,
          "3. flex_cost": format_currency(slot.unlockPrice),
          "4. bonus_bft": Constants::SLOT_BONUS_MULTIPLIERS[slot.id] || 0,
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
      total_cost = (total_flex * Constants::CURRENCY_RATES[:flex]).round(2)
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
      Constants::BASE_NORMAL_PART * slot_id
    end

    def calculate_bonus_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      bonus_percent = Constants::SLOT_BONUS_MULTIPLIERS[slot_id] || 0
      Constants::BASE_BONUS_PART * slot_id * bonus_percent
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
        "3. total_bonus_bft": Constants::SLOT_BONUS_MULTIPLIERS[nb_slots] || 0,
        "4. nb_tokens_roi": (base_roi * multiplier).round(0),
        "5. nb_charges_roi_1.0": (base_roi * multiplier).round(0),
        "6. nb_charges_roi_2.0": ((base_roi * multiplier) / 2.0).round(0),
        "7. nb_charges_roi_3.0": ((base_roi * multiplier) / 3.0).round(0)
      }
    end
  end
end
