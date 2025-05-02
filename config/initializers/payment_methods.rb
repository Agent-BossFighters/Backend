begin
  if defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.table_exists?("payment_methods")
    Rails.application.config.after_initialize do
      unless Rails.env.test?
        PaymentMethod.find_or_create_by(provider: "stripe") do |pm|
          pm.name = "Carte bancaire"
          pm.settings = { currencies: [ "eur", "usd" ] }
        end

        PaymentMethod.find_or_create_by(provider: "metamask") do |pm|
          pm.name = "MetaMask"
          pm.settings = {
            networks: [ "ethereum", "bsc" ],
            currencies: [ "eth", "bnb" ]
          }
        end

        PaymentMethod.find_or_create_by(provider: "coinbase") do |pm|
          pm.name = "Coinbase"
          pm.settings = { currencies: [ "btc", "eth", "usdt" ] }
        end

        PaymentMethod.find_or_create_by(provider: "binance") do |pm|
          pm.name = "Binance Pay"
          pm.settings = { currencies: [ "bnb", "busd" ] }
        end
      end
    end
  end
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
  # La base de données n'existe pas encore, on ignore silencieusement
end
