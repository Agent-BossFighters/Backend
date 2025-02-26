module DataLab
  module Constants
    module CurrencyConstants
      # Taux de conversion des devises vers USD
      # FLEX: basé sur le pack le plus grand (67,330 FLEX pour $499.99)
      # BFT: taux fixe de 0.01 USD
      # SM (Sponsor Marks): taux fixe de 0.01 USD
      CURRENCY_RATES = {
        flex: 0.00743,  # FLEX to USD (499.99 / 67_330)
        bft: 0.01,      # BFT to USD
        sm: 0.01,       # Sponsor Marks to USD
        energy: 1.49    # Energy cost in USD
      }.freeze

      # Packs FLEX disponibles avec leurs bonus
      FLEX_PACKS = [
        { amount: 480, price: 4.99, bonus: 0 },      # 0.0104 par FLEX
        { amount: 1_730, price: 14.99, bonus: 20 },  # 0.00867 par FLEX
        { amount: 3_610, price: 29.99, bonus: 25 },  # 0.00831 par FLEX
        { amount: 6_250, price: 49.99, bonus: 30 },  # 0.00800 par FLEX
        { amount: 12_990, price: 99.99, bonus: 35 }, # 0.00770 par FLEX
        { amount: 67_330, price: 499.99, bonus: 40 } # 0.00743 par FLEX
      ].freeze
    end
  end
end
