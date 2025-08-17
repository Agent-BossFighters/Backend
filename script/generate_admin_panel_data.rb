#!/usr/bin/env ruby
# Script de génération des données pour les onglets Admin Panel - Item crafting
# Usage: RAILS_ENV=staging bin/rails runner script/generate_admin_panel_data.rb

puts "🔧 Génération des données Admin Panel - Item crafting..."
puts "=" * 60

# 1. FORGE SETTINGS - Merge Digital
puts "\n📦 Création des Forge Settings - Merge Digital..."
merge_digital_data = {
  "Common" => { nb_previous_required: 0, cash: 0 },
  "Uncommon" => { nb_previous_required: 2, cash: 1000 },
  "Rare" => { nb_previous_required: 2, cash: 2000 },
  "Epic" => { nb_previous_required: 2, cash: 4000 },
  "Legendary" => { nb_previous_required: 2, cash: 8000 },
  "Mythic" => { nb_previous_required: 2, cash: 16000 },
  "Exalted" => { nb_previous_required: 2, cash: 0 },
  "Exotic" => { nb_previous_required: 2, cash: 0 },
  "Transcendent" => { nb_previous_required: 2, cash: 0 },
  "Unique" => { nb_previous_required: 2, cash: 0 }
}

Rarity.order(:id).each do |rarity|
  data = merge_digital_data[rarity.name] || { nb_previous_required: 2, cash: 10 }
  
  setting = ForgeSetting.find_or_initialize_by(
    rarity: rarity,
    operation_type: "merge_digital"
  )
  
  setting.assign_attributes(data)
  setting.save!
  
  puts "  ✓ #{rarity.name}: #{data.map { |k, v| "#{k}=#{v}" }.join(', ')}"
end

# 2. FORGE SETTINGS - Merge NFT
puts "\n🎨 Création des Forge Settings - Merge NFT..."
merge_nft_data = {
  "Common" => { supply: 5000, nb_previous_required: 0, cash: 0, fusion_core: 0, bft_tokens: 0, sponsor_marks_reward: 0 },
  "Uncommon" => { supply: 2000, nb_previous_required: 2, cash: 1000, fusion_core: 0, bft_tokens: 46, sponsor_marks_reward: 8 },
  "Rare" => { supply: 1500, nb_previous_required: 2, cash: 2000, fusion_core: 1, bft_tokens: 102, sponsor_marks_reward: 19 },
  "Epic" => { supply: 750, nb_previous_required: 2, cash: 4000, fusion_core: 3, bft_tokens: 314, sponsor_marks_reward: 28 },
  "Legendary" => { supply: 500, nb_previous_required: 2, cash: 8000, fusion_core: 10, bft_tokens: 966, sponsor_marks_reward: 91 },
  "Mythic" => { supply: 200, nb_previous_required: 2, cash: 16000, fusion_core: 32, bft_tokens: 2973, sponsor_marks_reward: 700 },
  "Exalted" => { supply: 100, nb_previous_required: 2, cash: 32000, fusion_core: 104, bft_tokens: 9147, sponsor_marks_reward: 2300 },
  "Exotic" => { supply: 50, nb_previous_required: 2, cash: 64000, fusion_core: 334, bft_tokens: 28146, sponsor_marks_reward: 7600 },
  "Transcendent" => { supply: 25, nb_previous_required: 2, cash: 128000, fusion_core: 1069, bft_tokens: 86602, sponsor_marks_reward: 10900 },
  "Unique" => { supply: 1, nb_previous_required: 3, cash: 256000, fusion_core: 2600, bft_tokens: 335172, sponsor_marks_reward: 23000 }
}

Rarity.order(:id).each do |rarity|
  data = merge_nft_data[rarity.name] || { supply: 5000, nb_previous_required: 2, cash: 10, fusion_core: 1, bft_tokens: 100, sponsor_marks_reward: 20 }
  
  setting = ForgeSetting.find_or_initialize_by(
    rarity: rarity,
    operation_type: "merge_nft"
  )
  
  setting.assign_attributes(data)
  setting.save!
  
  puts "  ✓ #{rarity.name}: supply=#{data[:supply]}, previous=#{data[:nb_previous_required]}, bft=#{data[:bft_tokens]}, sp_marks=#{data[:sponsor_marks_reward]}"
end

# 3. FORGE SETTINGS - Craft NFT
puts "\n⚡ Création des Forge Settings - Craft NFT..."
craft_nft_data = {
  "Common" => { supply: 5_000, nb_digital_required: 1, bft_tokens: 43, sponsor_marks_reward: 3 },
  "Uncommon" => { supply: 2000, nb_digital_required: 1, bft_tokens: 132, sponsor_marks_reward: 8 },
  "Rare" => { supply: 1000, nb_digital_required: 1, bft_tokens: 409, sponsor_marks_reward: 19 },
  "Epic" => { supply: 750, nb_digital_required: 1, bft_tokens: 1256, sponsor_marks_reward: 64 },
  "Legendary" => { supply: 500, nb_digital_required: 1, bft_tokens: 3865, sponsor_marks_reward: 260 },
  "Mythic" => { supply: 200, nb_digital_required: 1, bft_tokens: 11892, sponsor_marks_reward: 500 },
  "Exalted" => { supply: 100, nb_digital_required: 75, bft_tokens: 32000, sponsor_marks_reward: 150 },
  "Exotic" => { supply: 50, nb_digital_required: 100, bft_tokens: 64000, sponsor_marks_reward: 200 },
  "Transcendent" => { supply: 25, nb_digital_required: 150, bft_tokens: 128000, sponsor_marks_reward: 300 },
  "Unique" => { supply: 1, nb_digital_required: 250, bft_tokens: 256000, sponsor_marks_reward: 500 }
}

Rarity.order(:id).each do |rarity|
  data = craft_nft_data[rarity.name] || { supply: 1000, nb_digital_required: 10, bft_tokens: 100, sponsor_marks_reward: 20 }
  
  setting = ForgeSetting.find_or_initialize_by(
    rarity: rarity,
    operation_type: "craft_nft"
  )
  
  setting.assign_attributes(data)
  setting.save!
  
  puts "  ✓ #{rarity.name}: supply=#{data[:supply]}, digital=#{data[:nb_digital_required]}, bft=#{data[:bft_tokens]}, sp_marks=#{data[:sponsor_marks_reward]}"
end

# 4. PERKS LOCK SETTINGS
puts "\n🔒 Création des Perks Lock Settings..."
perks_lock_data = {
  "Common" => { star_0: 2, star_1: 2, star_2: 2, star_3: 2 },
  "Uncommon" => { star_0: 4, star_1: 4, star_2: 4, star_3: 4 },
  "Rare" => { star_0: 10, star_1: 10, star_2: 10, star_3: 10 },
  "Epic" => { star_0: 10, star_1: 10, star_2: 15, star_3: 15 },
  "Legendary" => { star_0: 21, star_1: 21, star_2: 21, star_3: 21 },
  "Mythic" => { star_0: 31, star_1: 31, star_2: 31, star_3: 31 },
  "Exalted" => { star_0: 52, star_1: 52, star_2: 52, star_3: 52 },
  "Exotic" => { star_0: 83, star_1: 83, star_2: 83, star_3: 83 },
  "Transcendent" => { star_0: 144, star_1: 144, star_2: 144, star_3: 144 },
  "Unique" => { star_0: 206, star_1: 206, star_2: 206, star_3: 206 }
}

Rarity.order(:id).each do |rarity|
  data = perks_lock_data[rarity.name] || { star_0: 2, star_1: 2, star_2: 2, star_3: 2 }
  
  setting = PerksLockSetting.find_or_initialize_by(rarity: rarity)
  setting.assign_attributes(data)
  setting.save!
  
  puts "  ✓ #{rarity.name}: 0★=#{data[:star_0]}, 1★=#{data[:star_1]}, 2★=#{data[:star_2]}, 3★=#{data[:star_3]}"
end

# 5. Nettoyage du cache
puts "\n🧹 Nettoyage du cache..."
Rails.cache.delete_matched("data_lab/forge/*")
puts "  ✓ Cache forge invalidé"

# 6. Récapitulatif
puts "\n📊 Récapitulatif des données créées:"
puts "  • Forge Settings (Merge Digital): #{ForgeSetting.where(operation_type: 'merge_digital').count} entrées"
puts "  • Forge Settings (Merge NFT): #{ForgeSetting.where(operation_type: 'merge_nft').count} entrées"
puts "  • Forge Settings (Craft NFT): #{ForgeSetting.where(operation_type: 'craft_nft').count} entrées"
puts "  • Perks Lock Settings: #{PerksLockSetting.count} entrées"
puts "  • Raretés configurées: #{Rarity.count} (#{Rarity.pluck(:name).join(', ')})"

puts "\n✅ Génération terminée avec succès!"
puts "💡 Vous pouvez maintenant accéder aux onglets Admin Panel:"
puts "   - Forge: Merge Digital"
puts "   - Forge: Merge NFT" 
puts "   - Forge: Craft NFT"
puts "   - Perks Lock"
