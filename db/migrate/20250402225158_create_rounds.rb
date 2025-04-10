class CreateRounds < ActiveRecord::Migration[7.1]
  def change
    create_table :rounds do |t|
      t.integer :round_number, null: false
      t.decimal :team_a_damage, precision: 10, scale: 2, default: 0
      t.decimal :team_b_damage, precision: 10, scale: 2, default: 0
      t.decimal :team_a_survival_time, precision: 10, scale: 2, default: 0
      t.decimal :team_b_survival_time, precision: 10, scale: 2, default: 0
      t.integer :team_a_points, default: 0
      t.integer :team_b_points, default: 0
      t.references :match, null: false, foreign_key: { to_table: :tournament_matches }
      t.references :boss_a, foreign_key: { to_table: :users }
      t.references :boss_b, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :rounds, [:match_id, :round_number], unique: true
  end
end
