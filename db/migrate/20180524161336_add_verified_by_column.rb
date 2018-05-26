class AddVerifiedByColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :verified_by, :string, default: nil
  end
end
