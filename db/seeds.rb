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
  'items.rb'          # Création de tous les items (badges et contrats)
]

puts "\nDébut du seeding..."
seed_files.each do |file|
  puts "\nSeeding #{file}..."
  load Rails.root.join('db', 'seeds', file)
end

# Données de test pour janvier 2025
puts "Creating test matches for January 2025..."

# Constantes pour la variation des données
MAPS = ['toxic_river', 'award', 'radiation_rift']
BUILDS = ['Aggressive Build', 'Defensive Build', 'Speed Build', 'Tank Build']
RESULTS = ['win', 'loss', 'draw']
RARITIES = ['common', 'rare', 'epic', 'legendary', 'mythic', 'exalted']

# Création de matches pour chaque jour de janvier 2025
(1..31).each do |day|
  # 2-5 matches par jour
  rand(2..5).times do
    match = Match.create!(
      user_id: 1,  # Assurez-vous que cet utilisateur existe
      date: DateTime.new(2025, 1, day, rand(8..22), rand(0..59)),  # Heure aléatoire entre 8h et 22h
      build: BUILDS.sample,
      map: MAPS.sample,
      time: rand(5..20),  # Temps de match entre 5 et 20 minutes
      result: RESULTS.sample,
      totalToken: rand(50..200),  # BFT entre 50 et 200
      totalPremiumCurrency: rand(30..100),  # FLEX entre 30 et 100
      bonusMultiplier: rand(1.0..2.0).round(2),
      perksMultiplier: rand(1.0..1.5).round(2)
    )

    # Ajout de 1 à 3 badges par match
    rand(1..3).times do |i|
      BadgeUsed.create!(
        match: match,
        slot: i + 1,
        rarity: RARITIES.sample
      )
    end
  end
end

puts "Created test matches for January 2025"

puts "\n✓ Seeding completed successfully! 🌱"
