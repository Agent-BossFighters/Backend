class AddAutoCreateTeamsToTournaments < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :auto_create_teams, :boolean, default: false
  end
end
