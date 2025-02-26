module DataLab
  module Constants
    module MatchConstants
      include CurrencyConstants

      ENERGY_CONSUMPTION = {
        RATE_PER_MINUTE: 0.1
      }.freeze

      LUCK_RATES = {
        'common' => 1,
        'rare' => 2,
        'epic' => 3,
        'legendary' => 4,
        'mythic' => 5,
        'exalted' => 6,
        'transcendent' => 7
      }.freeze

      VALID_MAPS = %w[toxic_river award radiation_rift].freeze
    end
  end
end
