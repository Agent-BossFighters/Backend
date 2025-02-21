class AddRarityAndSlotToBadgeUseds < ActiveRecord::Migration[8.0]
  def change
    add_column :badge_useds, :rarity, :string
    add_column :badge_useds, :slot, :integer
  end
end
