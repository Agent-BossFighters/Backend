class ChangeTeamsCaptainIdNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :teams, :captain_id, true
  end
end
