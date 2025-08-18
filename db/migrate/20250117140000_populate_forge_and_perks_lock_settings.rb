class PopulateForgeAndPerksLockSettings < ActiveRecord::Migration[8.0]
  def up
    # Vérifier que les tables existent
    return unless table_exists?(:forge_settings) && table_exists?(:perks_lock_settings) && table_exists?(:rarities)

    puts "🔧 Peuplement des tables Forge et Perks Lock Settings..."

    # 1. FORGE SETTINGS - Merge Digital
    puts "📦 Création des Forge Settings - Merge Digital..."
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

    populate_forge_settings("merge_digital", merge_digital_data)

    # 2. FORGE SETTINGS - Merge NFT
    puts "🎨 Création des Forge Settings - Merge NFT..."
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

    populate_forge_settings("merge_nft", merge_nft_data)

    # 3. FORGE SETTINGS - Craft NFT
    puts "⚡ Création des Forge Settings - Craft NFT..."
    craft_nft_data = {
      "Common" => { supply: 5000, nb_digital_required: 1, bft_tokens: 43, sponsor_marks_reward: 3 },
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

    populate_forge_settings("craft_nft", craft_nft_data)

    # 4. PERKS LOCK SETTINGS
    puts "🔒 Création des Perks Lock Settings..."
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

    populate_perks_lock_settings(perks_lock_data)

    puts "✅ Peuplement terminé avec succès!"
  end

  def down
    # Supprimer uniquement les données créées par cette migration
    execute "DELETE FROM forge_settings WHERE operation_type IN ('merge_digital', 'merge_nft', 'craft_nft')"
    execute "DELETE FROM perks_lock_settings"
    puts "🗑️ Données Forge et Perks Lock supprimées"
  end

  private

  def populate_forge_settings(operation_type, data)
    # Récupérer les raretés existantes
    existing_rarities = execute("SELECT id, name FROM rarities ORDER BY id").to_a.to_h { |row| [row["name"], row["id"]] }
    
    data.each do |rarity_name, attributes|
      rarity_id = existing_rarities[rarity_name]
      next unless rarity_id

      # Construire la requête d'insertion ou mise à jour
      columns = attributes.keys.map(&:to_s)
      values = attributes.values
      
      # Créer la requête UPSERT pour PostgreSQL
      sql = <<~SQL
        INSERT INTO forge_settings (rarity_id, operation_type, #{columns.join(', ')}, created_at, updated_at)
        VALUES (#{rarity_id}, '#{operation_type}', #{values.map { |v| v.nil? ? 'NULL' : v }.join(', ')}, NOW(), NOW())
        ON CONFLICT (rarity_id, operation_type)
        DO UPDATE SET
          #{columns.map { |col| "#{col} = EXCLUDED.#{col}" }.join(', ')},
          updated_at = NOW()
      SQL

      execute(sql)
      puts "  ✓ #{rarity_name} (#{operation_type}): #{attributes.inspect}"
    end
  end

  def populate_perks_lock_settings(data)
    # Récupérer les raretés existantes
    existing_rarities = execute("SELECT id, name FROM rarities ORDER BY id").to_a.to_h { |row| [row["name"], row["id"]] }
    
    data.each do |rarity_name, attributes|
      rarity_id = existing_rarities[rarity_name]
      next unless rarity_id

      # Créer la requête UPSERT pour PostgreSQL
      sql = <<~SQL
        INSERT INTO perks_lock_settings (rarity_id, star_0, star_1, star_2, star_3, created_at, updated_at)
        VALUES (#{rarity_id}, #{attributes[:star_0]}, #{attributes[:star_1]}, #{attributes[:star_2]}, #{attributes[:star_3]}, NOW(), NOW())
        ON CONFLICT (rarity_id)
        DO UPDATE SET
          star_0 = EXCLUDED.star_0,
          star_1 = EXCLUDED.star_1,
          star_2 = EXCLUDED.star_2,
          star_3 = EXCLUDED.star_3,
          updated_at = NOW()
      SQL

      execute(sql)
      puts "  ✓ #{rarity_name}: 0★=#{attributes[:star_0]}, 1★=#{attributes[:star_1]}, 2★=#{attributes[:star_2]}, 3★=#{attributes[:star_3]}"
    end
  end
end
