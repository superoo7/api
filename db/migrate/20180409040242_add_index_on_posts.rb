class AddIndexOnPosts < ActiveRecord::Migration[5.1]
  def change
    add_index :posts, [:is_active, :payout_value]
  end
end
