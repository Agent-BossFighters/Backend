class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :invitation_code
      t.decimal :total_damage, precision: 10, scale: 2, default: 0
      t.decimal :total_survival_time, precision: 10, scale: 2, default: 0
      t.references :tournament, null: false, foreign_key: true
      t.references :captain, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :teams, :invitation_code, unique: true, where: "invitation_code IS NOT NULL"
    add_index :teams, [:tournament_id, :name], unique: true
  end
end
