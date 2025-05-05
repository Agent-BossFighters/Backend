class AddSlotValuesToSlots < ActiveRecord::Migration[8.0]
  def change
    add_column :slots, :flex_value, :integer
    add_column :slots, :cost_value, :float
    add_column :slots, :bonus_value, :float
  end
end
