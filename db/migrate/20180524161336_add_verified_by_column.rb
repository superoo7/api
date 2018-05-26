class AddVerifiedByColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :verified_by, :string, default: nil

    Post.where('created_at < ?', Date.today).update_all(is_verified: true, verified_by: 'steemhunt')
    Post.where('created_at >= ?', Date.today).where(is_verified: true).update_all(verified_by: 'project7')
  end
end
