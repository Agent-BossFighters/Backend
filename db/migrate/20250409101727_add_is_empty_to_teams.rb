class AddIsEmptyToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :is_empty, :boolean, default: false
  end
end
