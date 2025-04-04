class CreateTournamentAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :tournament_admins do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :is_creator, null: false, default: false

      t.timestamps
    end

    add_index :tournament_admins, [:tournament_id, :user_id], unique: true
    add_index :tournament_admins, [:tournament_id, :is_creator]
  end
end
