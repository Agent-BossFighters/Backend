puts "\nCréation des currencies..."

game = Game.find_by!(name: "Boss Fighters")

# Définition des currencies de Boss Fighters
currencies = [
  {
    name: "CASH",
    onChain: false,
    price: 1.0,
    game: game
  },
  {
    name: "FLEX",
    onChain: false,
    price: 0.0104,
    game: game
  },
  {
    name: "$BFT",
    onChain: true,
    price: 0.0230,
    game: game
  },
  {
    name: "Sponsor Marks",
    onChain: true,
    price: 0.0280,
    game: game
  },
  {
    name: "Fame Points",
    onChain: false,
    price: 0.0,
    game: game
  }
]

# Création des currencies
currencies.each do |currency_data|
  puts "- Création de la currency: #{currency_data[:name]}"
  Currency.find_or_create_by!(name: currency_data[:name]) do |c|
    c.onChain = currency_data[:onChain]
    c.price = currency_data[:price]
    c.game = currency_data[:game]
  end
end

puts "✓ Currencies créées avec succès"
