class AddSpOnUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :vesting_shares, :float, default: -1.0
  end
end
