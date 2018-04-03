class AddSessionCountOnUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :session_count, :integer, default: 0
  end
end
