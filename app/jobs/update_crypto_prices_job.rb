class UpdateCryptoPricesJob < ApplicationJob
  queue_as :default

  def perform
    # Mettre à jour les prix des crypto-monnaies
    DataLab::CoinmarketcapService.update_crypto_prices

    # Replanifier le job pour la prochaine exécution
    interval = Rails.application.config.coinmarketcap.fetch(:update_interval, 5.minutes)
    self.class.set(wait: interval).perform_later
  end
end
