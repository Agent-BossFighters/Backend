puts "\nCréation des items..."

# Définition des items avec leurs caractéristiques
items = [
  # Badges
  {
    name: "Rookie",
    type_name: "Badge",
    rarity_name: "Common",
    efficiency: 1.0,
    supply: 200_000,
    floorPrice: 7.99,
    farming: { in_game_time: 60 },
    crafting: {
      flex_craft: 1_320,
      sponsor_mark_craft: 0,
      nb_lower_badge_to_craft: 0,
      craft_tokens: 112,
      sponsor_marks_reward: 26
    },
    recharge: {
      max_energy_recharge: 1,
      time_to_charge: 480,
      flex_charge: 500,
      sponsor_mark_charge: 150
    }
  },
  {
    name: "Initiate",
    type_name: "Badge",
    rarity_name: "Uncommon",
    efficiency: 2.05,
    supply: 100_000,
    floorPrice: 28.50,
    farming: { in_game_time: 120 },
    crafting: {
      flex_craft: 293,
      sponsor_mark_craft: 2_400,
      nb_lower_badge_to_craft: 2,
      craft_tokens: 343,
      sponsor_marks_reward: 80
    },
    recharge: {
      max_energy_recharge: 2,
      time_to_charge: 465,
      flex_charge: 1400,
      sponsor_mark_charge: 350
    }
  },
  {
    name: "Encore",
    type_name: "Badge",
    rarity_name: "Rare",
    efficiency: 4.20,
    supply: 50_000,
    floorPrice: 82.50,
    farming: { in_game_time: 180 },
    crafting: {
      flex_craft: 1_356,
      sponsor_mark_craft: 4_100,
      nb_lower_badge_to_craft: 2,
      craft_tokens: 812,
      sponsor_marks_reward: 250
    },
    recharge: {
      max_energy_recharge: 3,
      time_to_charge: 450,
      flex_charge: 2520,
      sponsor_mark_charge: 1023
    }
  },
  {
    name: "Contender",
    type_name: "Badge",
    rarity_name: "Epic",
    efficiency: 12.92,
    supply: 25_000,
    floorPrice: 410.00,
    farming: { in_game_time: 240 },
    crafting: {
      flex_craft: 25_900,
      sponsor_mark_craft: 10_927,
      nb_lower_badge_to_craft: 3,
      craft_tokens: 812,
      sponsor_marks_reward: 760
    },
    recharge: {
      max_energy_recharge: 4,
      time_to_charge: 435,
      flex_charge: 4800,
      sponsor_mark_charge: 1980
    }
  },
  {
    name: "Challenger",
    type_name: "Badge",
    rarity_name: "Legendary",
    efficiency: 39.74,
    supply: 10_000,
    floorPrice: 1000.00,
    farming: { in_game_time: 300 },
    crafting: {
      flex_craft: 99_400,
      sponsor_mark_craft: 21_700,
      nb_lower_badge_to_craft: 3,
      craft_tokens: 2500,
      sponsor_marks_reward: 2300
    },
    recharge: {
      max_energy_recharge: 5,
      time_to_charge: 420,
      flex_charge: 12000,
      sponsor_mark_charge: 4065
    }
  },
  {
    name: "Veteran",
    type_name: "Badge",
    rarity_name: "Mythic",
    efficiency: 122.19,
    supply: 5_000,
    floorPrice: 4000.00,
    farming: { in_game_time: 360 },
    crafting: {
      flex_craft: 92_700,
      sponsor_mark_craft: 28_222,
      nb_lower_badge_to_craft: 3,
      craft_tokens: 7692,
      sponsor_marks_reward: 7200
    },
    recharge: {
      max_energy_recharge: 6,
      time_to_charge: 405,
      flex_charge: 21000,
      sponsor_mark_charge: 8136
    }
  },
  {
    name: "Champion",
    type_name: "Badge",
    rarity_name: "Exalted",
    efficiency: 375.74,
    supply: 1_000,
    floorPrice: 100_000.00,
    farming: { in_game_time: 420 },
    crafting: {
      flex_craft: 368_192,
      sponsor_mark_craft: 219_946,
      nb_lower_badge_to_craft: 3,
      craft_tokens: 23669,
      sponsor_marks_reward: 3200
    },
    recharge: {
      max_energy_recharge: 7,
      time_to_charge: 390,
      flex_charge: 9800,
      sponsor_mark_charge: nil
    }
  },
  {
    name: "Olympian",
    type_name: "Badge",
    rarity_name: "Exotic",
    efficiency: 1540.54,
    supply: 250,
    floorPrice: 55_000.00,
    farming: { in_game_time: 480 },
    crafting: {
      flex_craft: 3_875,
      sponsor_mark_craft: 800,
      nb_lower_badge_to_craft: 4,
      craft_tokens: 39612,
      sponsor_marks_reward: 10000
    },
    recharge: {
      max_energy_recharge: 8,
      time_to_charge: 375,
      flex_charge: 11200,
      sponsor_mark_charge: nil
    }
  },
  {
    name: "Prodigy",
    type_name: "Badge",
    rarity_name: "Transcendent",
    efficiency: 6316.20,
    supply: 100,
    floorPrice: 150000.00,
    farming: { in_game_time: 540 },
    crafting: {
      flex_craft: 4_350,
      sponsor_mark_craft: 900,
      nb_lower_badge_to_craft: 4,
      craft_tokens: 224082,
      sponsor_marks_reward: 31400
    },
    recharge: {
      max_energy_recharge: 9,
      time_to_charge: 360,
      flex_charge: 12600,
      sponsor_mark_charge: nil
    }
  },
  {
    name: "MVP",
    type_name: "Badge",
    rarity_name: "Unique",
    efficiency: 25896.42,
    supply: 1,
    floorPrice: 500000.00,
    farming: { in_game_time: 600 },
    crafting: {
      flex_craft: 4_825,
      sponsor_mark_craft: 1000,
      nb_lower_badge_to_craft: 4,
      craft_tokens: 335172,
      sponsor_marks_reward: 97400
    },
    recharge: {
      max_energy_recharge: 10,
      time_to_charge: 345,
      flex_charge: 14000,
      sponsor_mark_charge: nil
    }
  },

  # Contracts
  {
    name: "Rookie",
    type_name: "Contract",
    rarity_name: "Common",
    efficiency: 1.0,
    supply: 50_000,
    floorPrice: 40.00,
    farming: { in_game_time: 48 * 60 },
    crafting: {
      flex_craft: 1_320,
      sponsor_mark_craft: 0,
      nb_lower_badge_to_craft: 0,
      craft_time: 120,  # 2h
      max_level: 10
    },
    recharge: {
      max_energy_recharge: 1,
      time_to_charge: 48 * 60, # 48h
      flex_charge: 130,
      sponsor_mark_charge: 290
    }
  },
  {
    name: "Initiate",
    type_name: "Contract",
    rarity_name: "Uncommon",
    efficiency: 2.05,
    supply: 35_000,
    floorPrice: 55.00,
    farming: { in_game_time: 72 * 60 },
    crafting: {
      flex_craft: 293,
      sponsor_mark_craft: 2_400,
      nb_lower_badge_to_craft: 2,
      craft_time: 180,  # 3h
      max_level: 20
    },
    recharge: {
      max_energy_recharge: 2,
      time_to_charge: 72 * 60, # 72h
      flex_charge: 440,
      sponsor_mark_charge: 960
    }
  },
  {
    name: "Encore",
    type_name: "Contract",
    rarity_name: "Rare",
    efficiency: 4.20,
    supply: 20_000,
    floorPrice: 120.00,
    farming: { in_game_time: 96 * 60 },
    crafting: {
      flex_craft: 1_356,
      sponsor_mark_craft: 4_100,
      nb_lower_badge_to_craft: 2,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 3,
      time_to_charge: 96 * 60, # 96h
      flex_charge: 1662,
      sponsor_mark_charge: 2943
    }
  },
  {
    name: "Contender",
    type_name: "Contract",
    rarity_name: "Epic",
    efficiency: 12.92,
    supply: 10_000,
    floorPrice: 390.00,
    farming: { in_game_time: 120 * 60 },
    crafting: {
      flex_craft: 25_900,
      sponsor_mark_craft: 10_927,
      nb_lower_badge_to_craft: 3,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 4,
      time_to_charge: 120 * 60, # 120h
      flex_charge: 5852,
      sponsor_mark_charge: 10340
    }
  },
  {
    name: "Challenger",
    type_name: "Contract",
    rarity_name: "Legendary",
    efficiency: 39.74,
    supply: 5_000,
    floorPrice: 560.00,
    farming: { in_game_time: 144 * 60 },
    crafting: {
      flex_craft: 99_400,
      sponsor_mark_craft: 21_700,
      nb_lower_badge_to_craft: 3,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 5,
      time_to_charge: 144 * 60, # 144h
      flex_charge: 19665,
      sponsor_mark_charge: 34770
    }
  },
  {
    name: "Veteran",
    type_name: "Contract",
    rarity_name: "Mythic",
    efficiency: 100.0,
    supply: 2_500,
    floorPrice: 789.00,
    farming: { in_game_time: 168 * 60 },
    crafting: {
      flex_craft: 368_192,
      sponsor_mark_craft: 60_500,
      nb_lower_badge_to_craft: 3,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 6,
      time_to_charge: 168 * 60, # 168h
      flex_charge: 57948,
      sponsor_mark_charge: 300642
    }
  },
  {
    name: "Champion",
    type_name: "Contract",
    rarity_name: "Exalted",
    efficiency: 250.0,
    supply: 1_000,
    floorPrice: 4_500.00,
    farming: { in_game_time: 192 * 60 },
    crafting: {
      flex_craft: 500_000,
      sponsor_mark_craft: 219_946,
      nb_lower_badge_to_craft: 3,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 7,
      time_to_charge: 192 * 60, # 192h
      flex_charge: 100000,
      sponsor_mark_charge: 500000
    }
  },
  {
    name: "Olympian",
    type_name: "Contract",
    rarity_name: "Exotic",
    efficiency: 625.0,
    supply: 250,
    floorPrice: 15_000.00,
    farming: { in_game_time: 216 * 60 },
    crafting: {
      flex_craft: 750_000,
      sponsor_mark_craft: 300_000,
      nb_lower_badge_to_craft: 4,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 8,
      time_to_charge: 216 * 60, # 216h
      flex_charge: 150000,
      sponsor_mark_charge: 750000
    }
  },
  {
    name: "Prodigy",
    type_name: "Contract",
    rarity_name: "Transcendent",
    efficiency: 1562.5,
    supply: 100,
    floorPrice: 45_000.00,
    farming: { in_game_time: 240 * 60 },
    crafting: {
      flex_craft: 1_000_000,
      sponsor_mark_craft: 400_000,
      nb_lower_badge_to_craft: 4,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 9,
      time_to_charge: 240 * 60, # 240h
      flex_charge: 200000,
      sponsor_mark_charge: 1000000
    }
  },
  {
    name: "MVP",
    type_name: "Contract",
    rarity_name: "Unique",
    efficiency: 3906.25,
    supply: 10,
    floorPrice: 135_000.00,
    farming: { in_game_time: 264 * 60 },
    crafting: {
      flex_craft: 1_500_000,
      sponsor_mark_craft: 500_000,
      nb_lower_badge_to_craft: 4,
      craft_time: 0, # N/A
      max_level: 0
    },
    recharge: {
      max_energy_recharge: 10,
      time_to_charge: 264 * 60, # 264h
      flex_charge: 250000,
      sponsor_mark_charge: 1500000
    }
  }
]

# Création des items
items.each do |item_data|
  puts "- Création de l'item: #{item_data[:name]} (#{item_data[:type_name]} - #{item_data[:rarity_name]})"

  # Trouver ou créer le type et la rareté
  type = Type.find_by!(name: item_data[:type_name])
  rarity = Rarity.find_by!(name: item_data[:rarity_name])

  # Créer l'item
  item = Item.create_with(
    efficiency: item_data[:efficiency],
    supply: item_data[:supply],
    floorPrice: item_data[:floorPrice]
  ).find_or_create_by!(
    name: item_data[:name],
    type: type,
    rarity: rarity
  )

  # Créer les données de farming si présentes
  if item_data[:farming]
    ItemFarming.create_with(
      in_game_time: item_data[:farming][:in_game_time],
      efficiency: item_data[:efficiency]
    ).find_or_create_by!(item: item)
  end

  # Créer les données de crafting si présentes
  if item_data[:crafting]
    ItemCrafting.create_with(
      flex_craft: item_data[:crafting][:flex_craft],
      sponsor_mark_craft: item_data[:crafting][:sponsor_mark_craft],
      nb_lower_badge_to_craft: item_data[:crafting][:nb_lower_badge_to_craft],
      craft_tokens: item_data[:crafting][:craft_tokens],
      sponsor_marks_reward: item_data[:crafting][:sponsor_marks_reward],
      craft_time: item_data[:crafting][:craft_time],
      max_level: item_data[:crafting][:max_level]
    ).find_or_create_by!(item: item)
  end

  # Créer les données de recharge si présentes
  if item_data[:recharge]
    ItemRecharge.create_with(
      max_energy_recharge: item_data[:recharge][:max_energy_recharge],
      time_to_charge: item_data[:recharge][:time_to_charge],
      flex_charge: item_data[:recharge][:flex_charge],
      sponsor_mark_charge: item_data[:recharge][:sponsor_mark_charge]
    ).find_or_create_by!(item: item)
  end
end

puts "✓ Items créés avec succès"
