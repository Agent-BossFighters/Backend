module DataLab
  class ContractsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user)
      @user = user
      @contracts_cache = nil
      @level_costs_cache = nil
      @user_rates = Constants::CurrencyConstants.user_currency_rates(@user)
      @currency_rates = {
        # "FLEX" => Currency.find_by(name: "FLEX")&.price || 0,
        "Sponsor Marks" => Currency.find_by(name: "Sponsor Marks")&.price || 0
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
          .where(types: { name: "Contract" })
          .order("rarities.id ASC")
          .to_a
    end

    def load_level_costs
      ::ContractLevelCost.order(:level).limit(100).to_a
    end

    def calculate_contracts_metrics(contracts)
      contracts.map do |contract|
        rarity = contract.rarity.name
        recharge_cost = calculate_recharge_cost(contract)
        craft_data = contract.item_crafting

        # Pour les raretés supérieures à Legendary, on retourne "N/A"
        is_high_rarity = %w[Exotic Transcendent Unique].include?(rarity)

        flex_craft = if is_high_rarity
          "N/A"
        else
          craft_data&.flex_craft || 0
        end

        marks_craft = if is_high_rarity
          "N/A"
        else
          craft_data&.sponsor_mark_craft || 0
        end

        # Calcul du total craft cost en dollars
        total_craft_cost = if is_high_rarity
          "N/A"
        else
          flex_value = flex_craft.to_i * @user_rates[:flex]
          marks_value = marks_craft.to_i * @currency_rates["Sponsor Marks"]
          format_currency(flex_value + marks_value)
        end

        {
          "1. rarity": rarity,
          "2. item": contract.name,
          "3. supply": contract.supply || 0,
          "4. floor_price": format_currency(contract.floorPrice),
          "5. lvl_max": craft_data&.max_level || "N/A",
          "6. max_energy": contract.item_recharge&.max_energy_recharge || 0,
          "7. time_to_craft": calculate_recharge_time(contract),
          "8. nb_badges_required": craft_data&.nb_lower_badge_to_craft || 0,
          "9. flex_craft": flex_craft,
          "10. sp_marks_craft": marks_craft,
          "11. total_craft_cost": total_craft_cost,
          "12. time_to_charge": format_hours(craft_data&.craft_time),
          "13. flex_charge": contract.item_recharge&.flex_charge || "N/A",
          "14. sp_marks_charge": contract.item_recharge&.sponsor_mark_charge || "N/A"
        }
      end
    end

    def calculate_level_up_costs
      sp_marks_data = []
      sp_marks_cost_data = []
      total_sp_marks_data = []
      total_cost_data = []
      total_sp_marks = 0
      previous_cost = 0

      @level_costs_cache.each do |level_cost|
        sp_marks = level_cost.sponsor_mark_cost
        sp_marks_cost = (sp_marks * @currency_rates["Sponsor Marks"]).round(2)
        total_sp_marks += sp_marks

        # Calcul du coût total (somme du coût précédent et du coût actuel)
        current_total_cost = previous_cost + sp_marks_cost
        previous_cost = current_total_cost

        sp_marks_data << sp_marks
        sp_marks_cost_data << format_currency(sp_marks_cost)
        total_sp_marks_data << total_sp_marks
        total_cost_data << format_currency(current_total_cost)
      end

      {
        sp_marks_nb: sp_marks_data,
        sp_marks_cost: sp_marks_cost_data,
        total_sp_marks: total_sp_marks_data,
        total_cost: total_cost_data
      }
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
      remaining_minutes = minutes % 60
      format("%dh%02d", hours, remaining_minutes)
    end
  end
end
