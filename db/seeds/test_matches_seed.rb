# Constantes pour la variation des données
MAPS = ['toxic_river', 'award', 'radiation_rift']
BUILDS = ['Aggressive Build', 'Defensive Build', 'Speed Build', 'Tank Build']
RESULTS = ['win', 'loss', 'draw']
RARITIES = ['common', 'rare', 'epic', 'legendary', 'mythic', 'exalted']

puts "Suppression des anciens matches..."
Match.destroy_all
BadgeUsed.destroy_all

puts "Creating test matches for January 2025..."

# Création de matches pour chaque jour de janvier 2025
(1..31).each do |day|
  # 2-5 matches par jour
  rand(2..5).times do
    match = Match.create!(
      user_id: 1,  # Assurez-vous que cet utilisateur existe
      date: DateTime.new(2025, 1, day, rand(8..22), rand(0..59)),
      build: BUILDS.sample,
      map: MAPS.sample,
      time: rand(5..20),
      result: RESULTS.sample,
      totalToken: rand(50..200),
      totalPremiumCurrency: rand(30..100),
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
