class AddCreatedAtOnHuntTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :hunt_transactions, :created_at, :datetime, null: false, default: Time.now
  end
end
