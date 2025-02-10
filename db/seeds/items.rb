puts "\nCréation des items..."

# Définition des items avec leurs caractéristiques
items = [
  # Badges
  {
    name: "Rookie Badge",
    type_name: "Badge",
    rarity_name: "Common",
    efficiency: 1.0,
    supply: 200_000,
    floorPrice: 7.98,
    farming: { ratio: 1.0, in_game_time: 600 }
  },
  {
    name: "Initiate Badge",
    type_name: "Badge",
    rarity_name: "Uncommon",
    efficiency: 2.05,
    supply: 100_000,
    floorPrice: 34.00,
    farming: { ratio: 2.05, in_game_time: 600 }
  },
  {
    name: "Encore Badge",
    type_name: "Badge",
    rarity_name: "Rare",
    efficiency: 4.20,
    supply: 50_000,
    floorPrice: 95.00,
    farming: { ratio: 2.15, in_game_time: 600 }
  },
  {
    name: "Contender Badge",
    type_name: "Badge",
    rarity_name: "Epic",
    efficiency: 12.92,
    supply: 25_000,
    floorPrice: 409.00,
    farming: { ratio: 8.72, in_game_time: 600 }
  },
  {
    name: "Challenger Badge",
    type_name: "Badge",
    rarity_name: "Legendary",
    efficiency: 39.74,
    supply: 10_000,
    floorPrice: 2_900.00,
    farming: { ratio: 26.82, in_game_time: 600 }
  },
  {
    name: "Veteran Badge",
    type_name: "Badge",
    rarity_name: "Mythic",
    efficiency: 100.0,
    supply: 5_000,
    floorPrice: 8_900.00,
    farming: { ratio: 60.0, in_game_time: 600 }
  },
  {
    name: "Champion Badge",
    type_name: "Badge",
    rarity_name: "Exalted",
    efficiency: 250.0,
    supply: 2_000,
    floorPrice: 25_000.00,
    farming: { ratio: 150.0, in_game_time: 600 }
  },
  {
    name: "Sovereign Badge",
    type_name: "Badge",
    rarity_name: "Exotic",
    efficiency: 625.0,
    supply: 1_000,
    floorPrice: 75_000.00,
    farming: { ratio: 375.0, in_game_time: 600 }
  },
  {
    name: "Ascendant Badge",
    type_name: "Badge",
    rarity_name: "Transcendent",
    efficiency: 1562.5,
    supply: 500,
    floorPrice: 225_000.00,
    farming: { ratio: 937.5, in_game_time: 600 }
  },
  {
    name: "Immortal Badge",
    type_name: "Badge",
    rarity_name: "Unique",
    efficiency: 3906.25,
    supply: 100,
    floorPrice: 675_000.00,
    farming: { ratio: 2343.75, in_game_time: 600 }
  },

  # Contracts
  {
    name: "Rookie Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Common",
    efficiency: 1.0,
    supply: 50_000,
    floorPrice: 40.00,
    farming: { ratio: 1.0, in_game_time: 48 * 60 },
    crafting: {
      flex_craft: 1_320,
      sponsor_mark_craft: 0,
      nb_lower_badge_to_craft: 0
    },
    recharge: {
      max_energy_recharge: 1,
      time_to_charge: 8 * 60,
      flex_charge: 130,
      sponsor_mark_charge: 290
    }
  },
  {
    name: "Initiate Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Uncommon",
    efficiency: 2.05,
    supply: 35_000,
    floorPrice: 55.00,
    farming: { ratio: 2.05, in_game_time: 72 * 60 },
    crafting: {
      flex_craft: 293,
      sponsor_mark_craft: 2_400,
      nb_lower_badge_to_craft: 2
    },
    recharge: {
      max_energy_recharge: 2,
      time_to_charge: 7 * 60 + 45,
      flex_charge: 440,
      sponsor_mark_charge: 960
    }
  },
  {
    name: "Encore Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Rare",
    efficiency: 4.20,
    supply: 20_000,
    floorPrice: 120.00,
    farming: { ratio: 2.15, in_game_time: 96 * 60 },
    crafting: {
      flex_craft: 1_356,
      sponsor_mark_craft: 4_100,
      nb_lower_badge_to_craft: 2
    },
    recharge: {
      max_energy_recharge: 3,
      time_to_charge: 7 * 60 + 30,
      flex_charge: 1_662,
      sponsor_mark_charge: 2_943
    }
  },
  {
    name: "Contender Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Epic",
    efficiency: 12.92,
    supply: 10_000,
    floorPrice: 390.00,
    farming: { ratio: 8.72, in_game_time: 120 * 60 },
    crafting: {
      flex_craft: 25_900,
      sponsor_mark_craft: 10_927,
      nb_lower_badge_to_craft: 3
    },
    recharge: {
      max_energy_recharge: 4,
      time_to_charge: 7 * 60 + 15,
      flex_charge: 5_852,
      sponsor_mark_charge: 10_340
    }
  },
  {
    name: "Challenger Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Legendary",
    efficiency: 39.74,
    supply: 5_000,
    floorPrice: 560.00,
    farming: { ratio: 26.82, in_game_time: 144 * 60 },
    crafting: {
      flex_craft: 99_400,
      sponsor_mark_craft: 21_700,
      nb_lower_badge_to_craft: 3
    },
    recharge: {
      max_energy_recharge: 5,
      time_to_charge: 7 * 60,
      flex_charge: 19_665,
      sponsor_mark_charge: 34_770
    }
  },
  {
    name: "Veteran Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Mythic",
    efficiency: 100.0,
    supply: 2_500,
    floorPrice: 789.00,
    farming: { ratio: 60.0, in_game_time: 168 * 60 },
    crafting: {
      flex_craft: 368_192,
      sponsor_mark_craft: 60_500,
      nb_lower_badge_to_craft: 3
    },
    recharge: {
      max_energy_recharge: 6,
      time_to_charge: 6 * 60 + 45,
      flex_charge: 57_948,
      sponsor_mark_charge: 300_642
    }
  },
  {
    name: "Champion Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Exalted",
    efficiency: 250.0,
    supply: 1_000,
    floorPrice: 4_500.00,
    farming: { ratio: 150.0, in_game_time: 192 * 60 },
    crafting: {
      flex_craft: "???",
      sponsor_mark_craft: 219_946,
      nb_lower_badge_to_craft: 3
    },
    recharge: {
      max_energy_recharge: 7,
      time_to_charge: 6 * 60 + 30,
      flex_charge: "???",
      sponsor_mark_charge: "???"
    }
  },
  {
    name: "Sovereign Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Exotic",
    efficiency: 625.0,
    supply: 250,
    floorPrice: 15_000.00,
    farming: { ratio: 375.0, in_game_time: 216 * 60 },
    crafting: {
      flex_craft: "???",
      sponsor_mark_craft: "???",
      nb_lower_badge_to_craft: 4
    },
    recharge: {
      max_energy_recharge: 8,
      time_to_charge: 6 * 60 + 15,
      flex_charge: "???",
      sponsor_mark_charge: "???"
    }
  },
  {
    name: "Ascendant Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Transcendent",
    efficiency: 1562.5,
    supply: 50,
    floorPrice: 50_000.00,
    farming: { ratio: 937.5, in_game_time: 240 * 60 },
    crafting: {
      flex_craft: "???",
      sponsor_mark_craft: "???",
      nb_lower_badge_to_craft: 4
    },
    recharge: {
      max_energy_recharge: 9,
      time_to_charge: 6 * 60,
      flex_charge: "???",
      sponsor_mark_charge: "???"
    }
  },
  {
    name: "Immortal Showrunner Contract",
    type_name: "Contract",
    rarity_name: "Unique",
    efficiency: 3906.25,
    supply: 1,
    floorPrice: 150_000.00,
    farming: { ratio: 2343.75, in_game_time: 264 * 60 },
    crafting: {
      flex_craft: "???",
      sponsor_mark_craft: "???",
      nb_lower_badge_to_craft: 4
    },
    recharge: {
      max_energy_recharge: 10,
      time_to_charge: 5 * 60 + 45,
      flex_charge: "???",
      sponsor_mark_charge: "???"
    }
  }
]

# Création des items
items.each do |item_data|
  puts "- Création de l'item: #{item_data[:name]} (#{item_data[:type_name]} - #{item_data[:rarity_name]})"

  item = Item.find_or_create_by!(name: item_data[:name]) do |i|
    i.type = Type.find_by!(name: item_data[:type_name])
    i.rarity = Rarity.find_by!(name: item_data[:rarity_name])
    i.efficiency = item_data[:efficiency]
    i.supply = item_data[:supply]
    i.floorPrice = item_data[:floorPrice]
  end

  # Création des données de farming
  if item_data[:farming]
    ItemFarming.find_or_create_by!(item: item) do |farming|
      farming.ratio = item_data[:farming][:ratio]
      farming.efficiency = item.efficiency
      farming.in_game_time = item_data[:farming][:in_game_time]
    end
  end

  # Création des données de crafting
  if item_data[:crafting]
    ItemCrafting.find_or_create_by!(item: item) do |crafting|
      crafting.flex_craft = item_data[:crafting][:flex_craft]
      crafting.sponsor_mark_craft = item_data[:crafting][:sponsor_mark_craft]
      crafting.nb_lower_badge_to_craft = item_data[:crafting][:nb_lower_badge_to_craft]
    end
  end

  # Création des données de recharge
  if item_data[:recharge]
    ItemRecharge.find_or_create_by!(item: item) do |recharge|
      recharge.max_energy_recharge = item_data[:recharge][:max_energy_recharge]
      recharge.time_to_charge = item_data[:recharge][:time_to_charge]
      recharge.flex_charge = item_data[:recharge][:flex_charge]
      recharge.sponsor_mark_charge = item_data[:recharge][:sponsor_mark_charge]
    end
  end
end

puts "✓ Items créés avec succès"
