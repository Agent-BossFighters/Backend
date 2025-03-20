module DataLab
  module Constants
    module CurrencyConstants
      # Taux de conversion des devises vers USD
      def self.currency_rates
        DataLab::CurrencyRatesService.get_rates
      end

      # Méthode pour obtenir les taux de Flex spécifiques à l'utilisateur
      def self.user_currency_rates(user)
        DataLab::CurrencyRatesService.get_user_rates(user)
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
