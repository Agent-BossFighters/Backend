module DataLab
  module Constants
    module MatchConstants
      include DataLab::Constants::CurrencyConstants

      ENERGY_CONSUMPTION = {
        ONE_ENERGY_MINUTES: 60.0
      }.freeze

      VALID_MAPS = %w[toxic_river award radiation_rift].freeze
    end
  end
end
