module DataLab
  module Constants
    module MatchConstants
      include DataLab::Constants::CurrencyConstants

      ENERGY_CONSUMPTION = {
        RATE_PER_MINUTE: 0.1
      }.freeze

      VALID_MAPS = %w[toxic_river award radiation_rift].freeze
    end
  end
end
