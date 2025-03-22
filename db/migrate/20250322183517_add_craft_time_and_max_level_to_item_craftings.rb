class AddCraftTimeAndMaxLevelToItemCraftings < ActiveRecord::Migration[8.0]
  def change
    add_column :item_craftings, :craft_time, :integer
    add_column :item_craftings, :max_level, :integer
  end
end
