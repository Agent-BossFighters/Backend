puts "- Création des slots de BADGEs"

game = Game.find_by!(name: "Boss Fighters")
flex = Currency.find_by!(name: "FLEX")

# Définition des slots avec leurs caractéristiques
slots = [
  # Slot de base gratuit (toujours débloqué)
  {
    currency: flex,
    game: game,
    unlocked: true,
    unlockCurrencyNumber: 0,
    unlockPrice: 0,
    bonus_multiplier: 0,    # 0% bonus
    bonus_bft_percent: 0.0, # 0% BFT bonus
    base_bonus_part: 0,     # Pas de bonus
    flex_value: 0,
    cost_value: 0.00,
    bonus_value: 0.0
  },
  # Premier slot payant
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 7_000,
    unlockPrice: 51.98,
    bonus_multiplier: 10,   # 10% bonus
    bonus_bft_percent: 1.0, # 1% BFT bonus
    base_bonus_part: 10,    # Bonus part de base
    flex_value: 7_000,
    cost_value: 51.98,
    bonus_value: 0.5
  },
  # Deuxième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 13_000,
    unlockPrice: 96.54,
    bonus_multiplier: 20,   # 20% bonus
    bonus_bft_percent: 4.5, # 4.5% BFT bonus
    base_bonus_part: 10,    # Bonus part de base
    flex_value: 13_000,
    cost_value: 96.54,
    bonus_value: 1.5
  },
  # Troisième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 20_000,
    unlockPrice: 148.52,
    bonus_multiplier: 30,   # 30% bonus
    bonus_bft_percent: 12.0, # 12% BFT bonus
    base_bonus_part: 10,     # Bonus part de base
    flex_value: 20_000,
    cost_value: 148.52,
    bonus_value: 3.0
  },
  # Quatrième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 26_000,
    unlockPrice: 193.07,
    bonus_multiplier: 40,   # 40% bonus
    bonus_bft_percent: 25.0, # 25% BFT bonus
    base_bonus_part: 10,     # Bonus part de base
    flex_value: 26_000,
    cost_value: 193.07,
    bonus_value: 5.0
  }
]

puts "  - (Re)création de #{slots.length} slots (1 gratuit, 4 payants)"

# Nettoyage idempotent fort: on réinitialise la table et la séquence pour garder des IDs 1..5
ActiveRecord::Base.connection.execute("TRUNCATE TABLE slots RESTART IDENTITY CASCADE")

slots.each do |slot_data|
  Slot.create!(slot_data)
end

puts "✓ Slots créés avec succès"
