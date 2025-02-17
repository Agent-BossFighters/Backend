module DataLab
  class CurrencyMetricsCalculator
    include Constants::Utils

    FLEX_PACKS = [
      { currencyNumber: 480, price: 4.99, bonus: 0 },
      { currencyNumber: 1_730, price: 14.99, bonus: 20 },
      { currencyNumber: 3_610, price: 29.99, bonus: 25 },
      { currencyNumber: 6_250, price: 49.99, bonus: 30 },
      { currencyNumber: 12_990, price: 99.99, bonus: 35 },
      { currencyNumber: 67_330, price: 499.99, bonus: 40 }
    ].freeze

    def initialize(user)
      @user = user
    end

    def calculate
      {
        flex_packs: calculate_flex_packs_metrics,
        currency_rates: calculate_currency_rates
      }
    end

    private

    def calculate_flex_packs_metrics
      FLEX_PACKS.map do |pack|
        base_amount = calculate_base_amount(pack[:currencyNumber], pack[:bonus])
        unit_price = calculate_unit_price(pack[:currencyNumber], pack[:price])

        {
          "1. currency_number": pack[:currencyNumber],
          "2. base_amount": base_amount,
          "3. bonus_percent": pack[:bonus],
          "4. bonus_amount": pack[:currencyNumber] - base_amount,
          "5. price": format_currency(pack[:price]),
          "6. unit_price": format_currency(unit_price)
        }
      end
    end

    def calculate_currency_rates
      {
        "1. flex_to_usd": Constants::FLEX_TO_USD,
        "2. bft_to_usd": Constants::BFT_TO_USD,
        "3. sm_to_usd": Constants::SM_TO_USD
      }
    end

    def calculate_base_amount(total_amount, bonus_percent)
      return total_amount if bonus_percent.zero?
      (total_amount / (1 + (bonus_percent / 100.0))).round
    end

    def calculate_unit_price(amount, price)
      (price.to_f / amount.to_f).round(5)
    end
  end
end
