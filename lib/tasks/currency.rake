namespace :currency do
  desc "Update cryptocurrency prices from CoinMarketCap API"
  task update_prices: :environment do
    puts "Updating cryptocurrency prices from CoinMarketCap..."
    DataLab::CoinmarketcapService.update_crypto_prices
    puts "Done!"
  end
end
