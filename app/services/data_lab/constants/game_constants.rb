module DataLab
  module Constants
    module GameConstants
      # Configuration des cycles de joueurs
      PLAYER_CYCLES = [
        {
          cycleName: "Daily Cycle",
          playerCycleType: 1,
          nbBadge: 3,
          minimumBadgeRarity: "Common",
          nbDateRepeat: 1
        },
        {
          cycleName: "Weekly Cycle",
          playerCycleType: 2,
          nbBadge: 5,
          minimumBadgeRarity: "Uncommon",
          nbDateRepeat: 7
        },
        {
          cycleName: "Monthly Cycle",
          playerCycleType: 3,
          nbBadge: 10,
          minimumBadgeRarity: "Rare",
          nbDateRepeat: 30
        }
      ].freeze

      # Règles de jeu fixes
      MATCHES_PER_CHARGE = 18
      MINUTES_PER_MATCH = 10
      HOURS_PER_ENERGY = 1

      # Temps de réduction possibles (en pourcentage)
      DISCOUNT_TIMES = [ 5, 9, 10, 13, 16, 20, 25 ].freeze
    end
  end
end
