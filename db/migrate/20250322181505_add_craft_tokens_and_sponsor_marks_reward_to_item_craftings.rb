class AddCraftTokensAndSponsorMarksRewardToItemCraftings < ActiveRecord::Migration[8.0]
  def change
    add_column :item_craftings, :craft_tokens, :integer
    add_column :item_craftings, :sponsor_marks_reward, :integer
  end
end
