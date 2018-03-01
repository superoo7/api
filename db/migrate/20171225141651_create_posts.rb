class CreatePosts < ActiveRecord::Migration[5.1]
  def change
    create_table :posts do |t|
      t.string :author, null: false

      t.string :url, null: false
      t.string :title, null: false
      t.string :tagline, null: false
      t.string :tags, array: true, default: []
      t.json :images
      t.json :beneficiaries
      t.string :permlink
      t.boolean :is_active, default: true

      # Caching variables
      t.float :payout_value, default: 0
      t.json :active_votes, default: []
      t.integer :comment_count, default: 0

      t.timestamps
    end

    add_index :posts, :url, unique: true
    add_index :posts, [:author, :permlink], unique: true
    add_index :posts, :created_at
  end
end
