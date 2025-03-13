class RemoveStripeSubscriptionIdFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :stripe_subscription_id, :string
    remove_index :users, :stripe_subscription_id if index_exists?(:users, :stripe_subscription_id)
  end
end
