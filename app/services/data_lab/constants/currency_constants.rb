module DataLab
  module Constants
    module CurrencyConstants
      # Taux de conversion des devises vers USD
      def self.currency_rates
        DataLab::CurrencyRatesService.get_rates
      end

      # Méthode pour accéder aux taux comme constante pour compatibilité
      def self.CURRENCY_RATES
        currency_rates
      end

      # Packs FLEX disponibles avec leurs bonus
      def self.flex_packs
        DataLab::CurrencyRatesService.get_flex_packs
      end

      # Méthode pour accéder aux packs comme constante pour compatibilité
      def self.FLEX_PACKS
        flex_packs
      end
    end
  end
end
