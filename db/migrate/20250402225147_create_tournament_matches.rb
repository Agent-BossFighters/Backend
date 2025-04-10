class CreateTournamentMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :tournament_matches do |t|
      t.integer :match_type, null: false
      t.integer :status, null: false, default: 0
      t.integer :round_number, null: false
      t.datetime :scheduled_time
      t.integer :team_a_points, default: 0
      t.integer :team_b_points, default: 0
      t.references :tournament, null: false, foreign_key: true
      t.references :team_a, null: false, foreign_key: { to_table: :teams }
      t.references :team_b, foreign_key: { to_table: :teams }
      t.references :boss, null: false, foreign_key: { to_table: :users }
      t.references :winner, foreign_key: { to_table: :teams }

      t.timestamps
    end

    add_index :tournament_matches, [:tournament_id, :round_number]
    add_index :tournament_matches, :status
  end
end
