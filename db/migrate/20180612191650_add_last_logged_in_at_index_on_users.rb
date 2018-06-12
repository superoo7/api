class AddLastLoggedInAtIndexOnUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :last_logged_in_at
  end
end
