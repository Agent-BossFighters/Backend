class AddZealyUserIdToUsers < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:users, :zealy_user_id)
      add_column :users, :zealy_user_id, :string
    end
  end
end
