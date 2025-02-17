module DataLab
  class CraftMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    # Constante pour le nombre d'items requis par rareté
    PREVIOUS_RARITY_NEEDED = {
      "Common" => 0,
      "Uncommon" => 2,
      "Rare" => 2,
      "Epic" => 3,
      "Legendary" => 3,
      "Mythic" => 3,
      "Exalted" => 3,
      "Exotic" => 4,
      "Transcendent" => 4,
      "Unique" => 4
    }.freeze

    def initialize(user)
      @user = user
      @badges = load_badges
    end

    def calculate
      @badges.map do |badge|
        rarity = badge.rarity.name
        flex_craft_cost = Constants::FLEX_CRAFT_COSTS[rarity]
        sp_marks_craft_cost = Constants::SP_MARKS_CRAFT_COSTS[rarity]

        {
          "1. rarity": rarity,
          "2. supply": badge.supply,
          "3. nb_previous_rarity_item": PREVIOUS_RARITY_NEEDED[rarity],
          "4. flex_craft": flex_craft_cost,
          "5. flex_craft_cost": format_currency(flex_craft_cost * Constants::FLEX_TO_USD),
          "6. sp_marks_craft": sp_marks_craft_cost,
          "7. sp_marks_value": format_currency(sp_marks_craft_cost * Constants::SM_TO_USD),
          "8. craft_time": format_hours(calculate_craft_time(rarity)),
          "9. total_craft_cost": format_currency(calculate_total_craft_cost(rarity))
        }
      end
    end

    private

    def load_badges
      Item.includes(:type, :rarity, :item_crafting, :item_farming, :item_recharge)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .sort_by { |badge| Constants::RARITY_ORDER.index(badge.rarity.name) }
    end

    def calculate_craft_time(rarity)
      index = Constants::RARITY_ORDER.index(rarity)
      return 0 unless index
      Constants::BASE_CRAFT_TIME + (index * Constants::CRAFT_TIME_INCREMENT)
    end

    def calculate_total_craft_cost(rarity)
      flex_cost = Constants::FLEX_CRAFT_COSTS[rarity] * Constants::FLEX_TO_USD
      sp_marks_cost = Constants::SP_MARKS_CRAFT_COSTS[rarity] * Constants::SM_TO_USD
      flex_cost + sp_marks_cost
    end

    def format_hours(minutes)
      "#{minutes}h"
    end

    def format_currency(amount)
      return nil if amount.nil?
      "$#{amount}"
    end
  end
end
