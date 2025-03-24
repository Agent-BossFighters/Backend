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
          .order('rarities.id ASC')
    end

    def calculate_contracts_metrics(contracts)
      contracts.map do |contract|
        rarity = contract.rarity.name
        recharge_cost = calculate_recharge_cost(contract)

        {
          "1. rarity": rarity,
          "2. item": contract.name,
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": contract.item_crafting&.max_level || 0,
          "6. max_energy": contract.item_recharge&.max_energy_recharge || 0,
          "7. time_to_craft": format_hours(calculate_craft_time(contract)),
          "8. nb_badges_required": contract.item_crafting&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": contract.item_crafting&.craft_tokens || 0,
          "10. sp_marks_craft": contract.item_crafting&.sponsor_marks_reward || 0,
          "11. time_to_charge": calculate_recharge_time(contract),
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

      ::ContractLevelCost.order(:level).limit(30).each do |level_cost|
        sp_marks = level_cost.sponsor_mark_cost
        sp_marks_cost = (sp_marks * 0.028).round(2)

        total_cost += sp_marks

        sp_marks_data << sp_marks
        sp_marks_cost_data << format_currency(sp_marks_cost)
        total_cost_data << total_cost
      end

      {
        sp_marks_nb: sp_marks_data,
        sp_marks_cost: sp_marks_cost_data,
        total_cost: total_cost_data
      }
    end

    def calculate_craft_time(contract)
      return 0 if contract.nil? || contract.item_crafting.nil?

      # Le temps de craft est stocké directement dans item_crafting
      contract.item_crafting.craft_time || 0
    end

    def calculate_recharge_cost(contract)
      return { flex: 0, sm: 0 } if contract.nil? || contract.item_recharge.nil?

      {
        flex: contract.item_recharge.flex_charge || 0,
        sm: contract.item_recharge.sponsor_mark_charge || 0
      }
    end

    def calculate_recharge_time(contract)
      return "N/A" if contract.nil? || contract.item_farming.nil?
      format_hours(contract.item_farming.in_game_time || 0)
    end

    def format_hours(minutes)
      return "N/A" if minutes.nil? || minutes.zero?
      hours = minutes / 60
      "#{hours}h"
    end
  end
end
