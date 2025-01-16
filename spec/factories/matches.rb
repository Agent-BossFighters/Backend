FactoryBot.define do
  factory :match do
    association :user
    sequence(:build) { |n| "Build #{n}" }
    date { Time.current }
    sequence(:map) { |n| "Map #{n}" }
    totalFee { 100 }
    feeCost { 10.0 }
    slots { 1 }
    luckrate { 1.0 }
    time { 600 }
    energyUsed { 50 }
    energyCost { 5.0 }
    totalToken { 1000 }
    tokenValue { 100.0 }
    totalPremiumCurrency { 10 }
    premiumCurrencyValue { 50.0 }
    profit { 150.0 }
    bonusMultiplier { 1.5 }
    perksMultiplier { 1.2 }
  end
end
