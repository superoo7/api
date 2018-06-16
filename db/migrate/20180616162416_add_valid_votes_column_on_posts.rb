class AddValidVotesColumnOnPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :valid_votes, :json, default: []
  end
end
