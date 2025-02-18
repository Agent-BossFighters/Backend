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
        craft_metrics = Constants::CRAFT_METRICS[rarity]
        next unless craft_metrics

        {
          "1. rarity": rarity,
          "2. supply": craft_metrics[:supply],
          "3. nb_previous_rarity_item": craft_metrics[:previous_rarity_needed],
          "4. flex_craft": craft_metrics[:bft_tokens],
          "5. flex_craft_cost": format_currency(craft_metrics[:bft_tokens] * Constants::CURRENCY_RATES[:bft]),
          "6. sp_marks_craft": craft_metrics[:sponsor_marks_reward],
          "7. sp_marks_value": format_currency(craft_metrics[:sponsor_marks_reward] * Constants::CURRENCY_RATES[:sm])
        }
      end.compact
    end

    private

    def load_badges
      Item.includes(:type, :rarity)
          .joins(:rarity)
          .where(types: { name: 'Badge' })
          .sort_by { |badge| Constants::RARITY_ORDER.index(badge.rarity.name) }
    end
  end
end
