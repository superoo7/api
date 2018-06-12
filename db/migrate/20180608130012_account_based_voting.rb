class AccountBasedVoting < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :reputation, :integer, default: 0
    add_column :users, :blacklisted_at, :datetime, default: nil
    add_column :posts, :hunt_score, :float, default: 0
    remove_index :posts, [:is_active, :payout_value]
    add_index :posts, :is_active
    add_index :users, [:encrypted_token, :reputation]
  end
end
