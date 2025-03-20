class AddFlexPackToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :flex_pack, :integer, default: 1
  end
end
