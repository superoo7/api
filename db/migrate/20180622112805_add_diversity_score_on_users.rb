class AddDiversityScoreOnUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :cached_diversity_score, :float, default: -1
    add_column :users, :diversity_score_updated_at, :datetime, default: nil
  end
end
