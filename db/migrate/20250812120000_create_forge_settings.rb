class CreateForgeSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :forge_settings do |t|
      t.references :rarity, null: false, foreign_key: true
      t.string :operation_type, null: false # merge_digital, merge_nft, craft_nft

      # Champs communs/optionnels selon l'opération
      t.integer :supply
      t.integer :nb_previous_required
      t.integer :nb_digital_required
      t.integer :cash
      t.integer :fusion_core
      t.integer :bft_tokens
      t.integer :sponsor_marks_reward

      t.timestamps
    end

    add_index :forge_settings, [:rarity_id, :operation_type], unique: true, name: "index_forge_settings_on_rarity_and_operation"
  end
end


