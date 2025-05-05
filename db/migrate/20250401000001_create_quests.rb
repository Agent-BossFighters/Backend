class CreateQuests < ActiveRecord::Migration[8.0]
  def up
    # Création de l'enum quest_type
    execute <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'quest_type') THEN
          CREATE TYPE quest_type AS ENUM ('daily', 'unique', 'weekly', 'social', 'event');
        END IF;
      END
      $$;
    SQL

    create_table :quests do |t|
      t.string :quest_id, null: false
      t.string :title, null: false, limit: 100
      t.text :description
      t.column :quest_type, :quest_type, null: false
      t.integer :xp_reward, null: false, default: 0
      t.string :icon_url
      t.integer :progress_required, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :quests, :quest_id, unique: true
  end

  def down
    drop_table :quests
    execute <<-SQL
      DROP TYPE IF EXISTS quest_type;
    SQL
  end
end
