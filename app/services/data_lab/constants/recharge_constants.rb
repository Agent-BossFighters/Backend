module DataLab
  module Constants
    module RechargeConstants
      RECHARGE_COSTS = {
        flex: {
          "Common" => 500,
          "Uncommon" => 1400,
          "Rare" => 2520,
          "Epic" => 4800,
          "Legendary" => 12000,
          "Mythic" => 21000,
          "Exalted" => 9800,
          "Exotic" => 11200,
          "Transcendent" => 12600,
          "Unique" => 14000
        }.freeze,
        sm: {
          "Common" => 150,
          "Uncommon" => 350,
          "Rare" => 1023,
          "Epic" => 1980,
          "Legendary" => 4065,
          "Mythic" => 8136,
          "Exalted" => nil,
          "Exotic" => nil,
          "Transcendent" => nil,
          "Unique" => nil
        }.freeze
      }.freeze
    end
  end
end
