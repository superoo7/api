class SyncColumnNameWithSteem < ActiveRecord::Migration[5.1]
  def change
    rename_column :posts, :comment_count, :children
  end
end
