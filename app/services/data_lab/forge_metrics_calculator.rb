module DataLab
  class ForgeMetricsCalculator
    include Constants::Utils

    def initialize(user)
      @user = user
      @currency_rates = {
        "bft" => Constants::CurrencyConstants.currency_rates[:bft],
        "sm" => Constants::CurrencyConstants.currency_rates[:sm]
      }
    end

    # params: type => "merge"|"craft", item => "digital"|"nft"
    def calculate(type: "merge", item: "digital")
      if type == "merge" && item == "digital"
        merge_digital_table
      elsif type == "merge" && item == "nft"
        merge_nft_table
      elsif type == "craft" && item == "nft"
        craft_nft_table
      else
        []
      end
    end

    private

    def merge_digital_table
      # Inclure toutes les raretés disponibles, ordonnées
      rarities = Rarity.order(:id).to_a
      rarities.map do |rarity|
        fs = ForgeSetting.find_by(rarity: rarity, operation_type: "merge_digital")
        {
          "RARITY": rarity.name,
          "NB PREVIOUS RARITY ITEM": fs&.nb_previous_required,
          "CASH": fs&.cash
        }
      end
    end

    def merge_nft_table
      rarities = Rarity.order(:id).to_a
      rarities.map do |rarity|
        fs = ForgeSetting.find_by(rarity: rarity, operation_type: "merge_nft")
        bft_tokens = fs&.bft_tokens
        sp_reward = fs&.sponsor_marks_reward
        bft_cost = bft_tokens ? (bft_tokens * @currency_rates["bft"]).round(2) : nil
        sp_value = sp_reward ? (sp_reward * @currency_rates["sm"]).round(2) : nil
        {
          "RARITY": rarity.name,
          "SUPPLY": fs&.supply,
          "NB PREVIOUS RARITY ITEM": fs&.nb_previous_required,
          "CASH": fs&.cash,
          "FUSION CORE": fs&.fusion_core,
          "$BFT": fs&.bft_tokens,
          "$BFT COST": bft_cost ? format_currency(bft_cost) : nil,
          "SP. MARKS REWARD": fs&.sponsor_marks_reward,
          "SP. MARKS VALUE": sp_value ? format_currency(sp_value) : nil
        }
      end
    end

    def craft_nft_table
      rarities = Rarity.order(:id).to_a
      rarities.map do |rarity|
        fs = ForgeSetting.find_by(rarity: rarity, operation_type: "craft_nft")
        bft_tokens = fs&.bft_tokens
        sp_reward = fs&.sponsor_marks_reward
        bft_cost = bft_tokens ? (bft_tokens * @currency_rates["bft"]).round(2) : nil
        sp_value = sp_reward ? (sp_reward * @currency_rates["sm"]).round(2) : nil
        {
          "RARITY": rarity.name,
          "SUPPLY": fs&.supply,
          "NB DIGITAL": fs&.nb_digital_required,
          "$BFT": fs&.bft_tokens,
          "$BFT COST": bft_cost ? format_currency(bft_cost) : nil,
          "SP. MARKS REWARD": fs&.sponsor_marks_reward,
          "SP. MARKS VALUE": sp_value ? format_currency(sp_value) : nil
        }
      end
    end
  end
end


