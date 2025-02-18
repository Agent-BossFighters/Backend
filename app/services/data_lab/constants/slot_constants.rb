module DataLab
  module Constants
    module SlotConstants
      SLOT_BONUS_MULTIPLIERS = {
        1 => 0,    # 0%
        2 => 10,   # 10%
        3 => 20,   # 20%
        4 => 30,   # 30%
        5 => 40    # 40%
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
      BASE_BONUS_PART = 10
    end
  end
end
