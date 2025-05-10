require "net/http"
require "json"

module DataLab
  class CoinmarketcapService
    class << self
      def update_crypto_prices
        # Récupérer toutes les devises marquées comme étant sur la blockchain
        crypto_currencies = Currency.where(onChain: true)
        return if crypto_currencies.empty?

        # Extraire les symboles à récupérer de CoinMarketCap
        symbols = crypto_currencies.map do |currency|
          config[:symbols_map][currency.name] || currency.name.delete("$")
        end.join(",")

        # Faire la requête à l'API CoinMarketCap
        response = fetch_prices(symbols)
        return unless response[:success]

        # Mettre à jour les prix dans la base de données
        update_currencies(crypto_currencies, response[:data])

        # Invalider le cache des taux de change
        DataLab::CurrencyRatesService.invalidate_cache
      end

      private

      def config
        Rails.application.config.coinmarketcap
      end

      def fetch_prices(symbols)
        uri = URI("#{config[:base_url]}/cryptocurrency/quotes/latest")
        params = { symbol: symbols, convert: "USD" }
        uri.query = URI.encode_www_form(params)

        request = Net::HTTP::Get.new(uri)
        request["X-CMC_PRO_API_KEY"] = config[:api_key]
        request["Accept"] = "application/json"

        begin
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end

          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            { success: true, data: data["data"] }
          else
            Rails.logger.error("CoinMarketCap API error: #{response.code} - #{response.body}")
            { success: false, error: "API responded with #{response.code}" }
          end
        rescue => e
          Rails.logger.error("Error fetching CoinMarketCap data: #{e.message}")
          { success: false, error: e.message }
        end
      end

      def update_currencies(currencies, data)
        currencies.each do |currency|
          # Extraire le symbole correspondant
          symbol = config[:symbols_map][currency.name] || currency.name.delete("$")

          # Vérifier si nous avons des données pour ce symbole
          next unless data[symbol]

          # Extraire le prix USD
          price_usd = data[symbol]["quote"]["USD"]["price"]

          # Mettre à jour la devise
          if price_usd.present? && price_usd.positive?
            currency.update(price: price_usd)
            Rails.logger.info("Updated price for #{currency.name}: $#{price_usd}")
          end
        end
      end
    end
  end
end
