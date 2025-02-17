module DataLab
  class ContractsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user)
      @user = user
    end

    def calculate
      contracts = load_contracts
      {
        contracts: calculate_contracts_metrics(contracts),
        level_up: calculate_level_up_costs
      }
    end

    private

    def load_contracts
      Item.includes(:type, :rarity, :item_crafting, :item_farming, :item_recharge)
          .joins(:rarity)
          .where(types: { name: 'Contract' })
          .sort_by { |contract| Constants::RARITY_ORDER.index(contract.rarity.name) }
    end

    def calculate_contracts_metrics(contracts)
      contracts.map do |contract|
        rarity = contract.rarity.name
        recharge_cost = calculate_recharge_cost(rarity)
        max_energy = Constants::MAX_ENERGY_BY_RARITY[rarity]

        {
          "1. rarity": rarity,
          "2. item": Constants::BADGE_BASE_METRICS[rarity][:name] || "Unknown",
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": Constants::CONTRACT_MAX_LEVEL[rarity],
          "6. max_energy": max_energy,
          "7. time_to_craft": format_hours(calculate_craft_time(rarity)),
          "8. nb_badges_required": contract.item_crafting&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": Constants::FLEX_CRAFT_COSTS[rarity],
          "10. sp_marks_craft": Constants::SP_MARKS_CRAFT_COSTS[rarity],
          "11. time_to_charge": calculate_recharge_time(rarity),
          "12. flex_charge": recharge_cost&.[](:flex),
          "13. sp_marks_charge": recharge_cost&.[](:sm)
        }
      end
    end

    def calculate_level_up_costs
      sp_marks_data = []
      sp_marks_cost_data = []
      total_cost_data = []
      total_cost = 0

      (1..30).each do |level|
        sp_marks = calculate_sp_marks_for_level(level)
        total_cost += sp_marks
        sp_marks_cost = sp_marks * Constants::SM_TO_USD

        sp_marks_data << sp_marks
        sp_marks_cost_data << format_currency(sp_marks_cost)
        total_cost_data << format_currency(total_cost)
      end

      {
        sp_marks_nb: sp_marks_data,
        sp_marks_cost: sp_marks_cost_data,
        total_cost: total_cost_data
      }
    end

    def calculate_sp_marks_for_level(level)
      # Formula: 1.8433(X)^2 + 192.9014(X) + 0.5702 where X = level
      (1.8433 * level**2 + 192.9014 * level + 0.5702).round(2)
    end

    def calculate_craft_time(rarity)
      index = Constants::RARITY_ORDER.index(rarity)
      return 0 unless index
      Constants::BASE_CRAFT_TIME + (index * Constants::CRAFT_TIME_INCREMENT)
    end

    def format_hours(minutes)
      hours = minutes / 60
      "#{hours}h"
    end
  end
end
