class AddResultToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :result, :string
  end
end
