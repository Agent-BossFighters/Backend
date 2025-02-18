module DataLab
  module Constants
    module SlotConstants
      SLOT_BONUS_MULTIPLIERS = {
        1 => 1.0,    # 0% bonus
        2 => 1.1,    # 10% bonus
        3 => 1.2,    # 20% bonus
        4 => 1.3,    # 30% bonus
        5 => 1.4     # 40% bonus
      }.freeze

      # Bonus BFT total par nombre de slots
      TOTAL_BONUS_BFT_PERCENT = {
        1 => 1.0,   # 1%
        2 => 4.5,   # 4.5%
        3 => 12.0,  # 12%
        4 => 25.0,  # 25%
        5 => 40.0   # 40%
      }.freeze

      # Constantes pour les calculs de parts normales et bonus
      BASE_NORMAL_PART = 100
      BASE_BONUS_PART = 50
    end
  end
end
