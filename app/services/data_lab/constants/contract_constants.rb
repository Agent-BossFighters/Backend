module DataLab
  module Constants
    module ContractConstants
      CONTRACT_MAX_LEVEL = {
        "Common" => 10,
        "Uncommon" => 20,
        "Rare" => 30,
        "Epic" => 40,
        "Legendary" => 50,
        "Mythic" => 60,
        "Exalted" => 70,
        "Exotic" => 80,
        "Transcendent" => 90,
        "Unique" => 100
      }.freeze

      # Coûts fixes de montée de niveau jusqu'au niveau 30
      CONTRACT_LEVEL_UP_COSTS = {
        1 => 105,
        2 => 212,
        3 => 321,
        4 => 431,
        5 => 543,
        6 => 658,
        7 => 774,
        8 => 893,
        9 => 952,
        10 => 1014,
        11 => 1136,
        12 => 1261,
        13 => 1389,
        14 => 1519,
        15 => 1651,
        16 => 1786,
        17 => 1923,
        18 => 2063,
        19 => 2206,
        20 => 2351,
        21 => 2500,
        22 => 2625,  # +125
        23 => 2756,  # +131
        24 => 2901,  # +145
        25 => 3056,  # +155
        26 => 3222,  # +166
        27 => 3399,  # +177
        28 => 3587,  # +188
        29 => 3786,  # +199
        30 => 3996   # +210
      }.freeze
    end
  end
end
