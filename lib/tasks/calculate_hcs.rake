require 's_logger'

desc 'Calculate Hunt Curation Score'
task :calculate_hcs, [:days] => :environment do |t, args|
  DAILY_MAX_EARNING = 500
  DAILY_ABUSE_LIMIT = 2000

  days = args[:days].to_i

  logger = SLogger.new
  today = Time.zone.today.to_time + 1.day
  day_start = (today - (days).day).to_time
  day_end = (today - (days + 1).day).to_time

  posts = Post.where('created_at >= ? AND created_at < ?', day_end, day_start).
               where(is_active: true)

  logger.log "\n== Update HCS for #{posts.count} posts on day #{days} ==", true

  api = Radiator::Api.new
  users_scores = {}
  posts.each do |post|
    logger.log "@#{post.author}/#{post.permlink}"
    # post.sync! api.get_content(post.author, post.permlink)['result']

    post.active_votes.each do |v|
      # skip self voting
      next if v['voter'] == post.author

      # only daily active users on Steemhunt
      user = User.find_by(username: v['voter'])
      next if !user || !user.dau?

      score = v['percent'] / 100.0
      if users_scores[v['voter']]
        users_scores[v['voter']] += score
      else
        users_scores[v['voter']] = score
      end

      # logger.log "@#{v['voter']} + #{score} = #{users_scores[v['voter']]}"
    end
  end

  adjusted_scores = {}
  users_scores.each do |u, score|
    if users_scores[u] > DAILY_ABUSE_LIMIT
      adjusted_scores[u] = DAILY_MAX_EARNING + DAILY_ABUSE_LIMIT - users_scores[u]
    elsif users_scores[u] > DAILY_MAX_EARNING
      adjusted_scores[u] = DAILY_MAX_EARNING
    else
      adjusted_scores[u] = users_scores[u]
    end
  end
  adjusted_scores = adjusted_scores.sort_by {|k,v| v}.reverse

  adjusted_scores.each do |u, score|
    logger.log "@#{u}: #{sprintf("%+d", score)} (vp: #{users_scores[u]})"
    User.find_by(username: u).increment!(:hc_score, score) # doesn't change timestamps
  end

  # for all inactive users
  User.where.not(username: adjusted_scores.keys).update_all('hc_score = (CASE WHEN hc_score > 100 THEN (hc_score - 100) WHEN hc_score < 0 THEN hc_score ELSE 0 END)')
end