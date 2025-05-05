class AddCurrentJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :current_jti, :string
  end
end
