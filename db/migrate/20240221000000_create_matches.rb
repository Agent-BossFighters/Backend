class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :build
      t.datetime :date
      t.string :map
      t.integer :totalFee
      t.float :feeCost
      t.integer :slots
      t.float :luckrate
      t.integer :time
      t.integer :energyUsed
      t.float :energyCost
      t.integer :totalToken
      t.float :tokenValue
      t.integer :totalPremiumCurrency
      t.float :premiumCurrencyValue
      t.float :profit
      t.float :bonusMultiplier
      t.float :perksMultiplier

      t.timestamps
    end

    add_index :matches, [ :user_id, :date ]
  end
end
