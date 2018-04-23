require 'radiator'
require 's_logger'

desc 'Synchronize posts'
task :sync_posts => :environment do |t, args|
  logger = SLogger.new
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time
  week_ago_1 = (today - 8.days).to_time # take care of timezone difference
  week_ago_2 = (today - 9.days).to_time

  posts = Post.where('(created_at >= ? AND created_at < ?) OR (created_at >= ? AND created_at < ?)', yesterday, today, week_ago_2, week_ago_1).
               where(is_active: true)

  logger.log "UPDATES #{posts.count} POSTS", true

  api = Radiator::Api.new
  diff = 0
  posts.each do |post|
    logger.log "@#{post.author}/#{post.permlink}"
    old_votes = post.active_votes.size
    old_payout = post.payout_value
    old_comments = post.children
    post.sync! api.get_content(post.author, post.permlink)['result']

    diff += post.payout_value - old_payout
    logger.log "--> Payout: #{old_payout.round(2)} -> #{post.payout_value.round(2)}" if diff.abs > 0.1
    logger.log "--> Likes: #{old_votes} -> #{post.active_votes.size}" if post.active_votes.size != old_votes
    logger.log "--> Comments: #{old_comments} -> #{post.children}" if post.children != old_comments
  end

  logger.log "Finished with diff: + $#{diff.round(2)} SBD", true
end