class ChangeTotalTokenToDecimal < ActiveRecord::Migration[7.1]
  def up
    change_column :matches, :totalToken, :decimal, precision: 10, scale: 3
  end

  def down
    change_column :matches, :totalToken, :integer
  end
end
