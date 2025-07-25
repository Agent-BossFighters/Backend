class RemoveTimeFromMatches < ActiveRecord::Migration[8.0]
  def change
    remove_column :matches, :time, :integer
  end
end
