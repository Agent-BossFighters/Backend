class AddZealyQuestIdToQuests < ActiveRecord::Migration[8.0]
  def change
    add_column :quests, :zealy_quest_id, :string
  end
end
