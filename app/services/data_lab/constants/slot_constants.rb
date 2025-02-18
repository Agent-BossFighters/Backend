module DataLab
  module Constants
    module SlotConstants
      SLOT_BONUS_MULTIPLIERS = {
        1 => 0,    # 0% (bonus)
        2 => 10,   # 10% (bonus)
        3 => 20,   # 20% (bonus)
        4 => 30,   # 30% (bonus)
        5 => 40    # 40% (bonus)
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

      # Valeurs exactes pour chaque slot
      SLOT_VALUES = {
        1 => { flex: 0, cost: 0.00, bonus: 0.0 },
        2 => { flex: 7_000, cost: 51.98, bonus: 0.5 },
        3 => { flex: 13_000, cost: 96.54, bonus: 1.5 },
        4 => { flex: 20_000, cost: 148.52, bonus: 3.0 },
        5 => { flex: 26_000, cost: 193.07, bonus: 5.0 }
      }.freeze
    end
  end
end
