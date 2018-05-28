class AddCreatedAtOnHuntTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :hunt_transactions, :created_at, :datetime, null: false, default: Time.parse('2018-05-21 00:00 +09:00')
  end
end
