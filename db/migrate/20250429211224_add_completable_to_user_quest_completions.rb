class AddCompletableToUserQuestCompletions < ActiveRecord::Migration[7.0]
  def change
    add_column :user_quest_completions, :completable, :boolean, default: false, null: false
    add_index :user_quest_completions, :completable
  end
end
