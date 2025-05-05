class AddZealyQuestIdToQuests < ActiveRecord::Migration[8.0]
  def change
    remove_column :quests, :zealy_quest_id, :string
  end
end
