require_relative 'constants/currency_constants'
require_relative 'constants/badge_constants'
require_relative 'constants/slot_constants'
require_relative 'constants/recharge_constants'
require_relative 'constants/craft_constants'
require_relative 'constants/contract_constants'
require_relative 'constants/game_constants'
require_relative 'constants/match_constants'

module DataLab
  module Constants
    include CurrencyConstants
    include BadgeConstants
    include SlotConstants
    include RechargeConstants
    include CraftConstants
    include ContractConstants
    include GameConstants
    include MatchConstants

    # Méthodes utilitaires communes
    module Utils
      def format_currency(amount)
        return nil if amount.nil?
        "$#{format('%.2f', amount)}"
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
        return "8h00" unless rarity && BadgeConstants::RARITY_ORDER.include?(rarity)

        base_hours = 8
        decrement = 0.25 * BadgeConstants::RARITY_ORDER.index(rarity)
        hours = base_hours - decrement

        whole_hours = hours.floor
        minutes = ((hours - whole_hours) * 60).round
        format("%dh%02d", whole_hours, minutes)
      end

      def calculate_recharge_cost(rarity)
        return nil unless BadgeConstants::RARITY_ORDER.include?(rarity)

        flex_cost = RechargeConstants::RECHARGE_COSTS[:flex][rarity]
        sm_cost = RechargeConstants::RECHARGE_COSTS[:sm][rarity]

        return nil if flex_cost.nil? || sm_cost.nil?

        {
          flex: flex_cost,
          sm: sm_cost,
          total_usd: (flex_cost * CurrencyConstants.currency_rates[:flex] + sm_cost * CurrencyConstants.currency_rates[:sm]).round(2)
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
  end
end
