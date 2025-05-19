class ChangeEnergyUsedToDecimal < ActiveRecord::Migration[7.1]
  def up
    change_column :matches, :energyUsed, :decimal, precision: 10, scale: 3
  end

  def down
    change_column :matches, :energyUsed, :integer
  end
end
