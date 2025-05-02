class CreateTeamMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :team_members do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :slot_number, null: false
      t.boolean :is_boss_eligible, null: false, default: false

      t.timestamps
    end

    add_index :team_members, [ :team_id, :slot_number ], unique: true
    add_index :team_members, [ :team_id, :user_id ], unique: true
  end
end
