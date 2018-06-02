require 'radiator'
require 'utils'
require 's_logger'

desc 'Reward Voters'
task :reward_voters => :environment do |t, args|
  TEST_MODE = true # Should be false on production
  HUNT_DISTRIBUTION_VOTE = 40000.0
  PAYOUT_DECLINED = [
    'steemhunt', 'utopian-io',
    # Subscription based voting bots
    # TODO: Add more on list
    'adsactly', 'silvergoldbotty', 'sndbox', 'qurator'
  ]

  def get_bid_bot_ids
    JSON.parse(File.read("#{Rails.root}/db/bid_bot_ids.json"))
  end

  logger = SLogger.new
  api = Radiator::Api.new
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time

  logger.log "\n==\n========== #{HUNT_DISTRIBUTION_VOTE} HUNT DISTRIBUTION ON VOTERS ==========", true

  posts = Post.where('created_at >= ? AND created_at < ?', yesterday, today).
    where(is_active: true, is_verified: true).
    order('payout_value DESC')
  logger.log "Total #{posts.count} verified posts founds\n=="

  bid_bot_ids = get_bid_bot_ids
  rshares_by_users = {}
  posts.each_with_index do |post, i|
    logger.log "@#{post.author}/#{post.permlink}"

    # Get data from blockchain
    result = with_retry(3) do
      api.get_content(post.author, post.permlink)['result']
    end
    votes = result['active_votes']
    logger.log "--> VOTE COUNT: #{votes.size}"

    votes.each do |vote|
      if bid_bot_ids.include?(vote['voter'])
        logger.log "----> SKIP BIDBOT: #{vote['voter']}"
        next
      end

      if PAYOUT_DECLINED.include?(vote['voter'])
        logger.log "----> SKIP PAYOUT_DECLINED: #{vote['voter']}"
        next
      end

      if rshares_by_users[vote['voter']]
        rshares_by_users[vote['voter']] += vote['rshares'].to_i
      else
        rshares_by_users[vote['voter']] = vote['rshares'].to_i
      end
    end
  end

  # HUNT voting distribution
  total_rshares = rshares_by_users.values.sum.to_f
  rshares_by_users = rshares_by_users.sort_by {|k,v| v}.reverse

  rshares_by_users.each do |pair|
    username = pair[0]
    proportion = pair[1] / total_rshares
    hunt_amount = HUNT_DISTRIBUTION_VOTE * proportion

    if TEST_MODE
      logger.log "TEST - @#{username} received #{hunt_amount.round(2)} HUNT - #{(100 * proportion).round(4)}%"
    else
      HuntTransaction.reward_votings!(username, hunt_amount, yesterday)
      logger.log "@#{username} received #{hunt_amount.round(2)} HUNT - #{(100 * proportion).round(4)}%"
    end
  end
end