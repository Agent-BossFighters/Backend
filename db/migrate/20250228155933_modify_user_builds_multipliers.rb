class ModifyUserBuildsMultipliers < ActiveRecord::Migration[8.0]
  def change
    change_table :user_builds do |t|
      t.remove :bonusMultiplier
      t.remove :perksMultiplier
      t.float :bftBonus, default: 0.0
    end
  end
end
