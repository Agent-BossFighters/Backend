module DataLab
  module Constants
    module CraftConstants
      BASE_CRAFT_TIME = 120
      CRAFT_TIME_INCREMENT = 60

      CRAFT_METRICS = {
        "Common" => {
          supply: 5_000,
          previous_rarity_needed: 0,
          cash_cost: 1,
          bft_tokens: 112,
          sponsor_marks_reward: 26
        },
        "Uncommon" => {
          supply: 2_000,
          previous_rarity_needed: 2,
          cash_cost: 1,
          bft_tokens: 343,
          sponsor_marks_reward: 80
        },
        "Rare" => {
          supply: 1_500,
          previous_rarity_needed: 2,
          cash_cost: 1,
          bft_tokens: 812,
          sponsor_marks_reward: 250
        },
        "Epic" => {
          supply: 750,
          previous_rarity_needed: 2,
          cash_cost: 1500,
          bft_tokens: 812,
          sponsor_marks_reward: 760
        },
        "Legendary" => {
          supply: 500,
          previous_rarity_needed: 2,
          cash_cost: 3000,
          bft_tokens: 2500,
          sponsor_marks_reward: 2300
        },
        "Mythic" => {
          supply: 200,
          previous_rarity_needed: 2,
          cash_cost: 6000,
          bft_tokens: 7692,
          sponsor_marks_reward: 7200
        },
        "Exalted" => {
          supply: 100,
          previous_rarity_needed: 2,
          cash_cost: 12000,
          bft_tokens: 23669,
          sponsor_marks_reward: 3200
        },
        "Exotic" => {
          supply: 50,
          previous_rarity_needed: 2,
          cash_cost: 24000,
          bft_tokens: 39612,
          sponsor_marks_reward: 10000
        },
        "Transcendent" => {
          supply: 25,
          previous_rarity_needed: 2,
          cash_cost: 48000,
          bft_tokens: 224082,
          sponsor_marks_reward: 31400
        },
        "Unique" => {
          supply: 1,
          previous_rarity_needed: 2,
          cash_cost: 96000,
          bft_tokens: 335172,
          sponsor_marks_reward: 97400
        }
      }.freeze
    end
  end
end
