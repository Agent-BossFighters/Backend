module DataLab
  module Constants
    module MatchConstants
      include DataLab::Constants::CurrencyConstants

      ENERGY_CONSUMPTION = {
        RATE_PER_MINUTE: 0.1
      }.freeze

      LUCK_RATES = {
        '-' => 0,
        'common' => 100,
        'uncommon' => 205,
        'rare' => 420,
        'epic' => 1292,
        'legendary' => 3974,
        'mythic' => 12219,
        'exalted' => 37574,
        'exotic' => 154054,
        'transcendent' => 631620,
        'unique' => 2589642
      }.freeze

      VALID_MAPS = %w[toxic_river award radiation_rift].freeze
    end
  end
end
