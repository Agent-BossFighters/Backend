class NftGeneratorService
  class << self
    # Génère un prix d'achat aléatoire basé sur le prix plancher
    def generate_purchase_price(floor_price)
      variation = rand(0.8..1.2)
      (floor_price * variation).round(2)
    end

    # Génère un ID unique pour chaque NFT
    def generate_issue_id(user_id, item_id, index)
      "#{user_id}-#{item_id}-#{index + 1}"
    end
  end
end
