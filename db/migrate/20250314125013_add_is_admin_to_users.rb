class AddIsAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_admin, :boolean, default: false
    add_index :users, :is_admin
  end
end
