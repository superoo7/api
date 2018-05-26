class AddVerifiedByColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :verified_by, :string, default: nil

    today = Time.zone.today.to_time
    Post.where('created_at < ?', today).update_all(is_verified: true, verified_by: 'steemhunt')
    Post.where('created_at >= ?', today).where(is_verified: true).update_all(verified_by: 'project7')
  end
end
