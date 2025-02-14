# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Charger les seeds dans un ordre spécifique pour respecter les dépendances
seed_files = [
  'rarities.rb',      # Définition des raretés
  'types.rb',         # Définition des types d'items
  'game.rb',          # Création du jeu
  'currencies.rb',    # Création des currencies
  'currency_packs.rb',# Création des packs de currencies
  'slots.rb',         # Création des slots (dépend des currencies)
  'items.rb',         # Création de tous les items (badges et contrats)
  'item_crafting_farming.rb' # Configuration du crafting et farming des items
]

puts "\nDébut du seeding..."
seed_files.each do |file|
  puts "\nSeeding #{file}..."
  load Rails.root.join('db', 'seeds', file)
end

puts "\n✓ Seeding completed successfully! 🌱"
