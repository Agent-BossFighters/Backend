puts "Création des paramètres Forge (ForgeSettings)..."
rarities = Rarity.order(:id).to_a
ops = ["merge_digital", "merge_nft", "craft_nft"]

rarities.each do |rarity|
  ops.each do |op|
    ForgeSetting.find_or_create_by!(rarity: rarity, operation_type: op)
  end
end

puts "Création des paramètres Perks Lock..."
rarities.each do |rarity|
  pls = PerksLockSetting.find_or_initialize_by(rarity: rarity)
  pls.star_0 ||= 0
  pls.star_1 ||= 0
  pls.star_2 ||= 0
  pls.star_3 ||= 0
  pls.save!
end

puts "✓ Forge & Perks seeds initialisés"


