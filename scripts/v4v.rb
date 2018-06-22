def votee(username)
  Post.from('posts, json_array_elements(posts.valid_votes) v').
    where("v->>'voter' = ?", username).group(:author).count.sort_by { |_, v| v }.reverse
end
