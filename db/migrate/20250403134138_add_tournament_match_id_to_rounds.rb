class AddTournamentMatchIdToRounds < ActiveRecord::Migration[8.0]
  def change
    add_reference :rounds, :tournament_match, null: false, foreign_key: true
  end
end
