module DataLab
  class CostsCalculator
    include Constants::Utils
    include Constants::CurrencyConstants

    def initialize
      @currency_rates = DataLab::Constants::CurrencyConstants.currency_rates
    end

    def calculate_recharge_costs(item)
      return { flex_charge: 0, sponsor_mark_charge: 0, total_usd: 0 } unless item&.item_recharge

      base_flex_cost = calculate_base_flex_cost(item)
      base_sm_cost = calculate_base_sm_cost(base_flex_cost)

      {
        flex_charge: base_flex_cost,
        sponsor_mark_charge: base_sm_cost,
        total_usd: calculate_total_usd(base_flex_cost, base_sm_cost)
      }
    end

    def calculate_craft_costs(item)
      return { flex_craft: 0, sponsor_mark_craft: 0, total_usd: 0 } unless item&.item_crafting

      base_flex_cost = item.item_crafting.flex_craft || 0
      base_sm_cost = item.item_crafting.sponsor_mark_craft || 0

      {
        flex_craft: base_flex_cost,
        sponsor_mark_craft: base_sm_cost,
        total_usd: calculate_total_usd(base_flex_cost, base_sm_cost)
      }
    end

    private

    def calculate_base_flex_cost(item)
      return 0 unless item&.item_recharge

      # Calcul basé sur le temps de recharge et l'efficacité du badge
      base_efficiency = item.efficiency || 0
      recharge_time = item.item_recharge.time_to_charge || 0

      # Formule: coût = efficacité * (temps de recharge / 60)
      (base_efficiency * (recharge_time / 60.0)).round
    end

    def calculate_base_sm_cost(flex_cost)
      # Ratio de conversion FLEX vers Sponsor Marks (1:35)
      (flex_cost * 0.35).round
    end

    def calculate_total_usd(flex_cost, sm_cost)
      (flex_cost * @currency_rates[:flex] + sm_cost * @currency_rates[:sm]).round(2)
    end
  end
end
