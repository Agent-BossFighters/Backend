class CreatePerksLockSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :perks_lock_settings do |t|
      t.references :rarity, null: false, foreign_key: true, index: { unique: true }
      t.integer :star_0
      t.integer :star_1
      t.integer :star_2
      t.integer :star_3
      t.timestamps
    end
  end
end


