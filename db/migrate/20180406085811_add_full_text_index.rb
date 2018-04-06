class AddFullTextIndex < ActiveRecord::Migration[5.1]
  def up
    execute """
      CREATE OR REPLACE FUNCTION immutable_array_to_string(arr ANYARRAY, sep TEXT)
        RETURNS text
        AS $$
          SELECT array_to_string(arr, sep);
        $$
        LANGUAGE SQL
        IMMUTABLE;

      CREATE INDEX index_posts_full_text ON posts
        USING gin((
          to_tsvector('english', author) ||
          to_tsvector('english', title) ||
          to_tsvector('english', tagline) ||
          to_tsvector('english', immutable_array_to_string(tags, ' '))
        ));
    """
  end

  def down
    remove_index :posts, name: 'index_posts_full_text'
  end
end
