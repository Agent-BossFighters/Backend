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
        max_energy = calculate_max_energy(rarity)

        {
          "1. rarity": rarity,
          "2. item": Constants::BADGE_NAMES[rarity] || "Unknown",
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": calculate_contract_max_level(rarity),
          "6. max_energy": max_energy,
          "7. time_to_craft": format_hours(calculate_craft_time(rarity)),
          "8. nb_badges_required": contract.item_crafting&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": calculate_flex_craft_cost(rarity),
          "10. sp_marks_craft": calculate_sp_marks_craft_cost(rarity),
          "11. time_to_charge": calculate_recharge_time(rarity),
          "12. flex_charge": recharge_cost&.[](:flex),
          "13. sp_marks_charge": recharge_cost&.[](:sm)
        }
      end
    end

    def calculate_level_up_costs
      # D'après le notepad, les coûts de level up sont fixes par niveau
      (1..15).map do |level|
        sp_marks = case level
          when 1 then 420
          when 2 then 855
          when 3 then 1275
          when 4 then 1695
          when 5 then 2174
          when 6 then 2632
          when 7 then 2940
          when 8 then 760
          when 9 then 848
          when 10 then 4545
          when 11 then 1025
          when 12 then 1113
          when 13 then 1201
          when 14 then 1289
          when 15 then 1378
          else 0
        end

        {
          "1. level": level,
          "2. sp_marks_nb": sp_marks,
          "3. sp_marks_cost": format_currency(sp_marks * Constants::SM_TO_USD),
          "4. total_cost": format_currency(sp_marks * Constants::SM_TO_USD)
        }
      end
    end

    def calculate_contract_max_level(rarity)
      # D'après le notepad
      case rarity
      when "Common" then 10
      when "Uncommon" then 20
      when "Rare" then 30
      when "Epic" then 40
      when "Legendary" then 50
      when "Mythic" then 60
      when "Exalted" then 70
      when "Exotic" then 80
      when "Transcendent" then 90
      when "Unique" then 100
      else 0
      end
    end

    def calculate_craft_time(rarity)
      # D'après le notepad, temps de craft en heures
      case rarity
      when "Common" then 120
      when "Uncommon" then 180
      when "Rare" then 240
      when "Epic" then 300
      when "Legendary" then 360
      when "Mythic" then 420
      when "Exalted" then 480
      else 0
      end
    end

    def calculate_flex_craft_cost(rarity)
      # D'après le notepad
      case rarity
      when "Common" then 1300
      when "Uncommon" then 290
      when "Rare" then 1400
      when "Epic" then 6300
      when "Legendary" then 25600
      when "Mythic" then 92700
      when "Exalted" then 368192
      else 0
      end
    end

    def calculate_sp_marks_craft_cost(rarity)
      # D'après le notepad
      case rarity
      when "Common" then 0
      when "Uncommon" then 3967
      when "Rare" then 6616
      when "Epic" then 16556
      when "Legendary" then 27618
      when "Mythic" then 28222
      when "Exalted" then 219946
      else 0
      end
    end

    def format_hours(minutes)
      hours = minutes / 60
      "#{hours}h"
    end
  end
end
