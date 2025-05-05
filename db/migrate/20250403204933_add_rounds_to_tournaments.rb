class AddRoundsToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :rounds, :integer, null: false, default: 1
  end
end
