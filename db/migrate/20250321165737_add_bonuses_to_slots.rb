class AddBonusesToSlots < ActiveRecord::Migration[8.0]
  def change
    add_column :slots, :bonus_multiplier, :float
    add_column :slots, :bonus_bft_percent, :float
    add_column :slots, :base_bonus_part, :integer
  end
end
