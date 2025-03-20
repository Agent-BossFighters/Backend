module DataLab
  class CurrencyRatesService
    FLEX_PACKS = [
      { amount: 480, price: 4.99, bonus: 0 },      # 0.0104 par FLEX
      { amount: 1_730, price: 14.99, bonus: 20 },  # 0.00867 par FLEX
      { amount: 3_610, price: 29.99, bonus: 25 },  # 0.00831 par FLEX
      { amount: 6_250, price: 49.99, bonus: 30 },  # 0.00800 par FLEX
      { amount: 12_990, price: 99.99, bonus: 35 }, # 0.00770 par FLEX
      { amount: 67_330, price: 499.99, bonus: 40 } # 0.00743 par FLEX
    ].freeze

    # Index des packs pour faciliter la recherche
    PACK_IDS = {
      1 => 0, # 480 FLEX
      2 => 1, # 1_730 FLEX
      3 => 2, # 3_610 FLEX
      4 => 3, # 6_250 FLEX
      5 => 4, # 12_990 FLEX
      6 => 5  # 67_330 FLEX
    }.freeze

    def self.get_rates
      Rails.cache.fetch("currency_rates", expires_in: 1.hour) do
        {
          flex: Currency.find_by(name: "FLEX")&.price || 0.00743,
          bft: Currency.find_by(name: "$BFT")&.price || 3.0,
          sm: Currency.find_by(name: "Sponsor Marks")&.price || 0.01,
          energy: Currency.find_by(name: "Energy")&.price || 1.49
        }
      end
    end

    def self.get_flex_packs
      FLEX_PACKS
    end
    
    def self.invalidate_cache
      Rails.cache.delete("currency_rates")
    end

    # Récupère le taux FLEX spécifique à l'utilisateur
    def self.get_user_flex_rate(user)
      default_rate = 0.0104

      return default_rate unless user && user.flex_pack

      pack_index = PACK_IDS[user.flex_pack]
      return default_rate unless pack_index && FLEX_PACKS[pack_index]

      pack = FLEX_PACKS[pack_index]
      (pack[:price] / pack[:amount]).round(5)
    end

    def self.get_user_rates(user)
      rates = get_rates
      
      rates[:flex] = get_user_flex_rate(user)
      
      rates
    end
  end
end 