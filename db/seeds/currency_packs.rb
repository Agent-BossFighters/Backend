puts "\nCréation des currency packs..."

# Définition des packs pour chaque currency
Currency.find_each do |currency|
  currency_packs = case currency.name
  when "FLEX"
    [
      { currencyNumber: 480, price: 4.99, unitPrice: (4.99 / 480.0).round(5) },
      { currencyNumber: 1_730, price: 14.99, unitPrice: (14.99 / 1_730.0).round(5) },
      { currencyNumber: 3_610, price: 29.99, unitPrice: (29.99 / 3_610.0).round(5) },
      { currencyNumber: 6_250, price: 49.99, unitPrice: (49.99 / 6_250.0).round(5) },
      { currencyNumber: 12_990, price: 99.99, unitPrice: (99.99 / 12_990.0).round(5) },
      { currencyNumber: 67_330, price: 499.99, unitPrice: (499.99 / 67_330.0).round(5) }
    ]
  else
    []
  end

  if currency_packs.any?
    puts "- Création des packs pour #{currency.name}"

    currency_packs.each do |pack_data|
      CurrencyPack.find_or_create_by!(
        currency: currency,
        currencyNumber: pack_data[:currencyNumber]
      ) do |pack|
        pack.price = pack_data[:price]
        pack.unitPrice = pack_data[:unitPrice]
        puts "  - Pack de #{pack_data[:currencyNumber]} #{currency.name} à #{pack_data[:price]}$ (#{pack_data[:unitPrice]}$/unité)"
      end
    end
  end
end

puts "✓ Currency packs créés avec succès"
