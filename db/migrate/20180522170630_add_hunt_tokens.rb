class AddHuntTokens < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :hunt_balance, :decimal, default: 0.0
    add_column :users, :eth_address, :string, limit: 42, default: nil

    User.find_by(username: 'steemhunt').update(id: 0) # irreversible

    create_table :hunt_transactions do |t|
      t.references :sender_id, null: false
      t.references :receiver_id, null: false
      t.decimal :amount, null: false
      t.string :memo, default: nil
    end
  end
end
