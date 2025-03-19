module DataLab
  class CurrencyRatesService
    # Taux de change par défaut
    DEFAULT_RATES = {
      flex: 0.00743,
      bft: 3.0,
      sm: 0.028,  # Taux par défaut pour les Sponsor Marks
      energy: 1.49
    }.freeze

    FLEX_PACKS = [
      { amount: 480, price: 4.99, bonus: 0 },      # 0.0104 par FLEX
      { amount: 1_730, price: 14.99, bonus: 20 },  # 0.00867 par FLEX
      { amount: 3_610, price: 29.99, bonus: 25 },  # 0.00831 par FLEX
      { amount: 6_250, price: 49.99, bonus: 30 },  # 0.00800 par FLEX
      { amount: 12_990, price: 99.99, bonus: 35 }, # 0.00770 par FLEX
      { amount: 67_330, price: 499.99, bonus: 40 } # 0.00743 par FLEX
    ].freeze

    def self.get_rates
      Rails.cache.fetch("currency_rates", expires_in: 1.hour) do
        {
          flex: Currency.find_by(name: "FLEX")&.price || DEFAULT_RATES[:flex],
          bft: Currency.find_by(name: "$BFT")&.price || DEFAULT_RATES[:bft],
          sm: Currency.find_by(name: "Sponsor Marks")&.price || DEFAULT_RATES[:sm],  # Utiliser la valeur de la DB
          energy: Currency.find_by(name: "Energy")&.price || DEFAULT_RATES[:energy]
        }
      end
    end

    def self.get_flex_packs
      FLEX_PACKS
    end

    def self.invalidate_cache
      Rails.cache.delete("currency_rates")
    end
  end
end
