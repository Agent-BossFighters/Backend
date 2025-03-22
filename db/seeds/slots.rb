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
    base_bonus_part: 0      # Pas de bonus
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
    base_bonus_part: 10     # Bonus part de base
  },
  # Deuxième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 20_000,
    unlockPrice: 148.52,
    bonus_multiplier: 20,   # 20% bonus
    bonus_bft_percent: 4.5, # 4.5% BFT bonus
    base_bonus_part: 10     # Bonus part de base
  },
  # Troisième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 40_000,
    unlockPrice: 297.04,
    bonus_multiplier: 30,   # 30% bonus
    bonus_bft_percent: 12.0, # 12% BFT bonus
    base_bonus_part: 10     # Bonus part de base
  },
  # Quatrième slot
  {
    currency: flex,
    game: game,
    unlocked: false,
    unlockCurrencyNumber: 66_000,
    unlockPrice: 490.11,
    bonus_multiplier: 40,   # 40% bonus
    bonus_bft_percent: 25.0, # 25% BFT bonus
    base_bonus_part: 10     # Bonus part de base
  }
]

puts "  - Création de #{slots.length} slots (1 gratuit, 4 payants)"

# Création des slots
slots.each do |slot_data|
  Slot.create!(slot_data)
end

puts "✓ Slots créés avec succès"
