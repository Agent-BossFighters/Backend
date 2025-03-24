module DataLab
  class ContractsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user)
      @user = user
      @contracts_cache = nil
      @level_costs_cache = nil
      @currency_rates = {
        'FLEX' => Currency.find_by(name: 'FLEX')&.price || 0,
        'Sponsor Marks' => Currency.find_by(name: 'Sponsor Marks')&.price || 0
      }
    end

    def calculate
      @contracts_cache = load_contracts
      @level_costs_cache = load_level_costs

      {
        contracts: calculate_contracts_metrics(@contracts_cache),
        level_up: calculate_level_up_costs
      }
    end

    private

    def load_contracts
      Item.includes(:type, :rarity, :item_crafting, :item_farming, :item_recharge)
          .joins(:rarity)
          .where(types: { name: 'Contract' })
          .order('rarities.id ASC')
          .to_a
    end

    def load_level_costs
      ::ContractLevelCost.order(:level).limit(30).to_a
    end

    def calculate_contracts_metrics(contracts)
      contracts.map do |contract|
        rarity = contract.rarity.name
        recharge_cost = calculate_recharge_cost(contract)
        craft_data = contract.item_crafting

        {
          "1. rarity": rarity,
          "2. item": contract.name,
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": craft_data&.max_level || 0,
          "6. max_energy": contract.item_recharge&.max_energy_recharge || 0,
          "7. time_to_craft": format_hours(calculate_craft_time(contract)),
          "8. nb_badges_required": craft_data&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": craft_data&.craft_tokens || 0,
          "10. sp_marks_craft": craft_data&.sponsor_marks_reward || 0,
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

      @level_costs_cache.each do |level_cost|
        sp_marks = level_cost.sponsor_mark_cost
        sp_marks_cost = (sp_marks * @currency_rates['Sponsor Marks']).round(2)

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
