class CreateUserQuestCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_quest_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :quest_id, null: false
      t.date :completion_date
      t.integer :progress, null: false, default: 0
      
      t.timestamps
    end

    add_index :user_quest_completions, [:user_id, :quest_id, :completion_date], unique: true, name: 'idx_user_quests_unique_completion'
    add_foreign_key :user_quest_completions, :quests, column: :quest_id, primary_key: :quest_id
  end
end 