class AddVerifiedOnPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :is_verified, :boolean, default: false
  end
end
