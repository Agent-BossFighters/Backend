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
        recharge_cost = calculate_recharge_cost(rarity)

        {
          "1. rarity": rarity,
          "2. item": contract.name,
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": Constants::CONTRACT_MAX_LEVEL[rarity],
          "6. max_energy": contract.item_recharge&.max_energy_recharge || 0,
          "7. time_to_craft": format_hours(calculate_craft_time(rarity)),
          "8. nb_badges_required": contract.item_crafting&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": contract.item_crafting&.craft_tokens || 0,
          "10. sp_marks_craft": contract.item_crafting&.sponsor_marks_reward || 0,
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
        sp_marks = Constants::ContractConstants::CONTRACT_LEVEL_UP_COSTS[level]
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

    def calculate_craft_time(rarity)
      return 0 if rarity.nil?

      rarity_record = Rarity.find_by(name: rarity)
      return 0 if rarity_record.nil?

      # Calcul du temps de craft basé sur l'ID de la rareté
      craft_time = Constants::BASE_CRAFT_TIME + ((rarity_record.id - 1) * Constants::CRAFT_TIME_INCREMENT)

      # S'assurer que le temps de craft est positif
      [craft_time, 0].max
    end

    def calculate_recharge_cost(rarity)
      {
        flex: Constants::RECHARGE_COSTS[:flex][rarity],
        sm: Constants::RECHARGE_COSTS[:sm][rarity]
      }
    end

    def calculate_recharge_time(rarity)
      item = Item.joins(:rarity, :item_farming)
                 .where(rarities: { name: rarity }, types: { name: 'Contract' })
                 .first

      format_hours(item&.item_farming&.in_game_time || 0)
    end

    def format_hours(minutes)
      return "N/A" if minutes.nil? || minutes.zero?
      hours = minutes / 60
      "#{hours}h"
    end
  end
end
