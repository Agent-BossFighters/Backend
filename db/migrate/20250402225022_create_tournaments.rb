class CreateTournaments < ActiveRecord::Migration[7.1]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.integer :tournament_type, null: false
      t.integer :status, null: false, default: 0
      t.text :rules
      t.string :entry_code
      t.integer :agent_level_required, null: false, default: 0
      t.integer :players_per_team, null: false
      t.integer :min_players_per_team
      t.integer :max_teams, null: false
      t.boolean :is_premium_only, null: false, default: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :boss, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tournaments, :entry_code, unique: true, where: "entry_code IS NOT NULL"
    add_index :tournaments, :status
    add_index :tournaments, :tournament_type
  end
end
