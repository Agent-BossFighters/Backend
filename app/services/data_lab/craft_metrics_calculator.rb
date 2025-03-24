module DataLab
  class CraftMetricsCalculator
    include Constants::Utils

    def initialize(user)
      @user = user
      @badges = load_badges
    end

    def calculate
      @badges.map do |badge|
        rarity = badge.rarity.name
        craft_data = badge.item_crafting
        next unless craft_data

        {
          "1. rarity": rarity,
          "2. supply": badge.supply,
          "3. nb_previous_rarity_item": craft_data.nb_lower_badge_to_craft,
          "4. flex_craft": craft_data.craft_tokens,
          "5. flex_craft_cost": format_currency(craft_data.craft_tokens * Constants::CurrencyConstants.currency_rates[:bft]),
          "6. sp_marks_craft": craft_data.sponsor_marks_reward,
          "7. sp_marks_value": format_currency(craft_data.sponsor_marks_reward * Constants::CurrencyConstants.currency_rates[:sm])
        }
      end.compact
    end

    private

    def load_badges
      Item.includes(:type, :rarity, :item_crafting)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .order('rarities.id ASC')
    end
  end
end
