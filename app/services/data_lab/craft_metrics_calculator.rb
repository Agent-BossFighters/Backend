module DataLab
  class CraftMetricsCalculator
    include Constants::Utils

    def initialize(user)
      @user = user
      @badges = nil
      @currency_rates = {
        "bft" => Constants::CurrencyConstants.currency_rates[:bft],
        "sm" => Constants::CurrencyConstants.currency_rates[:sm]
      }
    end

    def calculate
      @badges = load_items
      @badges.map do |item|
        rarity = item.rarity.name
        craft_data = item.item_crafting
        next unless craft_data

        flex_cost = calculate_flex_cost(craft_data.craft_tokens)
        sp_marks_value = calculate_sp_marks_value(craft_data.sponsor_marks_reward)
        nb_previous_rarity = calculate_nb_previous_rarity(rarity)

        {
          "1. rarity": rarity,
          "2. supply": item.supply,
          "3. nb_previous_rarity_item": nb_previous_rarity,
          "4. flex_craft": craft_data.craft_tokens,
          "5. flex_craft_cost": format_currency(flex_cost),
          "6. sp_marks_craft": craft_data.sponsor_marks_reward,
          "7. sp_marks_value": format_currency(sp_marks_value)
        }
      end.compact
    end

    private

    def calculate_nb_previous_rarity(rarity)
      rarity.downcase == "common" ? 0 : 2
    end

    def load_items
      Item.includes(:type, :rarity, :item_crafting)
          .joins(:rarity)
          .where(types: { name: "Badge" })
          .order("rarities.id ASC")
          .to_a
    end

    def calculate_flex_cost(tokens)
      return 0 unless tokens
      (tokens * @currency_rates["bft"]).round(2)
    end

    def calculate_sp_marks_value(sp_marks)
      return 0 unless sp_marks
      (sp_marks * @currency_rates["sm"]).round(2)
    end
  end
end
