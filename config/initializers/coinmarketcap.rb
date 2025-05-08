Rails.application.config.coinmarketcap = {
  api_key: ENV["COINMARKETCAP_API_KEY"],
  base_url: "https://pro-api.coinmarketcap.com/v1",
  update_interval: 1.hour,
  symbols_map: {
    "$BFT" => "BFTOKEN" # Mapping du nom dans notre DB vers le symbole sur CoinMarketCap
    # Ajoutez d'autres mappings si nécessaire
  }
}
