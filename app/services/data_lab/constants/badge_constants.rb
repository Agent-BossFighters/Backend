module DataLab
  module Constants
    module BadgeConstants
      # Ordre des raretés
      RARITY_ORDER = [
        "Common", "Uncommon", "Rare", "Epic", "Legendary",
        "Mythic", "Exalted", "Exotic", "Transcendent", "Unique"
      ].freeze

      # Métriques de base par rareté
      BADGE_BASE_METRICS = {
        "Common" => {
          name: "Rookie",
          supply: 200_000,
          floor_price: 7.99,
          efficiency: 1.00,
          bft_per_minute: 10,
          max_energy: 1,
          in_game_time: 60
        },
        "Uncommon" => {
          name: "Initiate",
          supply: 100_000,
          floor_price: 28.50,
          efficiency: 2.05,
          bft_per_minute: 20,
          max_energy: 2,
          in_game_time: 120
        },
        "Rare" => {
          name: "Encore",
          supply: 50_000,
          floor_price: 82.50,
          efficiency: 4.20,
          bft_per_minute: 30,
          max_energy: 3,
          in_game_time: 180
        },
        "Epic" => {
          name: "Contender",
          supply: 25_000,
          floor_price: 410.00,
          efficiency: 12.92,
          bft_per_minute: 40,
          max_energy: 4,
          in_game_time: 240
        },
        "Legendary" => {
          name: "Challenger",
          supply: 10_000,
          floor_price: 1000.00,
          efficiency: 39.74,
          bft_per_minute: 50,
          max_energy: 5,
          in_game_time: 300
        },
        "Mythic" => {
          name: "Veteran",
          supply: 5_000,
          floor_price: 4000.00,
          efficiency: 122.19,
          bft_per_minute: 60,
          max_energy: 6,
          in_game_time: 360
        },
        "Exalted" => {
          name: "Champion",
          supply: 1_000,
          floor_price: 100_000.00,
          efficiency: 375.74,
          bft_per_minute: 70,
          max_energy: 7,
          in_game_time: 420
        },
        "Exotic" => {
          name: "Olympian",
          supply: 250,
          floor_price: 55_000.00,
          efficiency: 1540.54,
          bft_per_minute: 80,
          max_energy: 8,
          in_game_time: 480
        },
        "Transcendent" => {
          name: "Prodigy",
          supply: 100,
          floor_price: 150000.00,
          efficiency: 6316.20,
          bft_per_minute: 90,
          max_energy: 9,
          in_game_time: 540
        },
        "Unique" => {
          name: "MVP",
          supply: 1,
          floor_price: 500000.00,
          efficiency: 25896.42,
          bft_per_minute: 100,
          max_energy: 10,
          in_game_time: 600
        }
      }.freeze
    end
  end
end
