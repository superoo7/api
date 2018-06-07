require 'radiator'
require 'utils'
require 's_logger'

desc 'Reward Resteemers'
task :reward_resteemers => :environment do |t, args|
  TEST_MODE = false # Should be false on production
  HUNT_DISTRIBUTION_RESTEEM = 20000.0

  logger = SLogger.new
  api = Radiator::Api.new
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time

  logger.log "\n==========\n #{HUNT_DISTRIBUTION_RESTEEM} HUNT DISTRIBUTION ON RESTEEMERS"

  posts = Post.where('created_at >= ? AND created_at < ?', yesterday, today).
    where(is_active: true, is_verified: true).
    order('payout_value DESC')
  logger.log "Total #{posts.count} verified posts founds\n==========", true

  has_resteemed = {}
  bid_bot_ids = get_bid_bot_ids
  other_bot_ids = get_other_bot_ids
  posts.each_with_index do |post, i|
    logger.log "@#{post.author}/#{post.permlink}"

    resteemed_by = with_retry(3) do
      api.get_reblogged_by(post.author, post.permlink)['result']
    end

    logger.log "--> RESTEEM COUNT: #{resteemed_by}"
    resteemed_by.each do |username|
      if has_resteemed[username]
        logger.log "--> SKIP ALREADY_RT_ONCE: @#{username}"
        next
      end

      if bid_bot_ids.include?(username)
        logger.log "--> SKIP BID_BOT: @#{username}"
        next
      end

      if other_bot_ids.include?(username)
        logger.log "--> SKIP OTHER_BOT: @#{username}"
        next
      end

      if u = User.find_by(username: username)
        if u.first_logged_in? && u.dau?
          has_resteemed[username] = true
        else
          logger.log "--> SKIP NOT_ACTIVE_USER: @#{username}"
        end
      else
        logger.log "--> SKIP NOT_STEEMHUNT_USER: @#{username}"
      end
    end
  end

  # HUNT resteem distribution
  resteemed_users = has_resteemed.keys.sort
  hunt_per_resteem = HUNT_DISTRIBUTION_RESTEEM / resteemed_users.size
  resteemed_users.each do |username|
    HuntTransaction.reward_resteems!(username, hunt_per_resteem, yesterday) unless TEST_MODE
  end

  if TEST_MODE
    logger.log "\n==========\n TEST - Distributed #{hunt_per_resteem} HUNT to each of #{resteemed_users.size} users\n==========", true
  else
    logger.log "\n==========\n Distributed #{hunt_per_resteem} HUNT to #{resteemed_users.size} users\n==========", true
  end
end