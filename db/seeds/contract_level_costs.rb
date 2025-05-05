puts "\nCréation des coûts de niveau des contrats..."

# Définition des coûts de niveau pour les contrats
costs = [
  { level: 1, flex_cost: 100, sponsor_mark_cost: 105 },
  { level: 2, flex_cost: 200, sponsor_mark_cost: 212 },
  { level: 3, flex_cost: 300, sponsor_mark_cost: 321 },
  { level: 4, flex_cost: 400, sponsor_mark_cost: 431 },
  { level: 5, flex_cost: 500, sponsor_mark_cost: 543 },
  { level: 6, flex_cost: 600, sponsor_mark_cost: 658 },
  { level: 7, flex_cost: 700, sponsor_mark_cost: 774 },
  { level: 8, flex_cost: 800, sponsor_mark_cost: 893 },
  { level: 9, flex_cost: 900, sponsor_mark_cost: 952 },
  { level: 10, flex_cost: 1000, sponsor_mark_cost: 1014 },
  { level: 11, flex_cost: 1100, sponsor_mark_cost: 1136 },
  { level: 12, flex_cost: 1200, sponsor_mark_cost: 1261 },
  { level: 13, flex_cost: 1300, sponsor_mark_cost: 1389 },
  { level: 14, flex_cost: 1400, sponsor_mark_cost: 1519 },
  { level: 15, flex_cost: 1500, sponsor_mark_cost: 1651 },
  { level: 16, flex_cost: 1600, sponsor_mark_cost: 1786 },
  { level: 17, flex_cost: 1700, sponsor_mark_cost: 1923 },
  { level: 18, flex_cost: 1800, sponsor_mark_cost: 2063 },
  { level: 19, flex_cost: 1900, sponsor_mark_cost: 2206 },
  { level: 20, flex_cost: 2000, sponsor_mark_cost: 2351 },
  { level: 21, flex_cost: 2100, sponsor_mark_cost: 2500 },
  { level: 22, flex_cost: 2200, sponsor_mark_cost: 2625 },
  { level: 23, flex_cost: 2300, sponsor_mark_cost: 2756 },
  { level: 24, flex_cost: 2400, sponsor_mark_cost: 2901 },
  { level: 25, flex_cost: 2500, sponsor_mark_cost: 3056 },
  { level: 26, flex_cost: 2600, sponsor_mark_cost: 3222 },
  { level: 27, flex_cost: 2700, sponsor_mark_cost: 3399 },
  { level: 28, flex_cost: 2800, sponsor_mark_cost: 3587 },
  { level: 29, flex_cost: 2900, sponsor_mark_cost: 3786 },
  { level: 30, flex_cost: 3000, sponsor_mark_cost: 3996 },
  { level: 31, flex_cost: 3100, sponsor_mark_cost: 7752 },
  { level: 32, flex_cost: 3200, sponsor_mark_cost: 8061 },
  { level: 33, flex_cost: 3300, sponsor_mark_cost: 8374 },
  { level: 34, flex_cost: 3400, sponsor_mark_cost: 8690 },
  { level: 35, flex_cost: 3500, sponsor_mark_cost: 9010 },
  { level: 36, flex_cost: 3600, sponsor_mark_cost: 9334 },
  { level: 37, flex_cost: 3700, sponsor_mark_cost: 9661 },
  { level: 38, flex_cost: 3800, sponsor_mark_cost: 9993 },
  { level: 39, flex_cost: 3900, sponsor_mark_cost: 10327 },
  { level: 40, flex_cost: 4000, sponsor_mark_cost: 10666 }
]

# Création ou mise à jour des coûts de niveau
costs.each do |cost|
  ContractLevelCost.create_with(
    flex_cost: cost[:flex_cost],
    sponsor_mark_cost: cost[:sponsor_mark_cost]
  ).find_or_create_by!(level: cost[:level])
end

puts "✓ Coûts de niveau des contrats créés avec succès"
