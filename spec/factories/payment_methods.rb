FactoryBot.define do
  factory :payment_method do
    sequence(:name) { |n| "Payment Method #{n}" }
    sequence(:provider) { |n| "provider_#{n}" }
    is_active { true }
    settings { { currencies: [ 'eur' ] } }
  end
end
