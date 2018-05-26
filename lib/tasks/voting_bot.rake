require 'radiator'
require 's_logger'

# NOTE: The total voting power is not a constant number like 1000
#   it will be closer to 1100 because:
#   when someone cast 100% voting when they have 80% vp left,
#   it will deduct 0.8 * 100 * 0.02 = 1.6% vp (not 2.0%)
#
#   We need to fix this correctly later
POWER_TOTAL = 880.0
POWER_TOTAL_COMMENT = 100.0
POWER_TOTAL_MODERATOR = 10.0 # TODO: increase it to  100.0
POWER_MAX = 100.0
MAX_POST_VOTING_COUNT = 1000

def get_minimum_power(size)
  minimum = if size < 20
    10
  elsif size < 40
    5
  elsif size < 100
    2
  elsif size  < 200
    1
  else
    0.1
  end
end

# def evenly_distributed_array(size)
#   return Array.new(size, POWER_MAX) if size <= POWER_TOTAL /  POWER_MAX

#   average = POWER_TOTAL / size
#   array = Array.new(size, average)
#   half = (size / 2).floor

#   variation = [POWER_MAX - array[0], array[size - 1] - get_minimum_power(size)].min / half

#   half.times do |i|
#     array[i] = array[i] + variation * (half - i)
#     array[size - i - 1] = array[size - i - 1] - variation * (half - i)
#   end

#   array.map { |n| n.round(2) }
# end

# Ref: https://github.com/Steemhunt/web/issues/102
def natural_distribution_test(size, temperature)
  orders = (1..size - 1).to_a
  exponents = orders.map { |o| Math.exp(o / temperature.to_f) }
  sum = exponents.sum
  softmaxes = exponents.map { |e| e / sum }

  minimum = get_minimum_power(size)
  allocated = Array.new(size, minimum)
  allocated[0] = POWER_MAX
  available = POWER_TOTAL - POWER_MAX - minimum * (size - 1)

  (1..size - 1).each do |i|
    allocated[i] += (available * softmaxes[size -  i - 1])
  end

  allocated
end

# def actual_vp_left(array)
#   vp_left = 100.0
#   array.each { |vp| vp_left -= (vp_left / 100) * vp * 0.02 }

#   vp_left
# end

def natural_distributed_array(size)
  return Array.new(size, POWER_MAX) if size <= POWER_TOTAL /  POWER_MAX

  minimum = get_minimum_power(size)

  selected = nil
  (1..50).each do |t|
    test_array = natural_distribution_test(size, t)
    if test_array.any? { |n| n > POWER_MAX || n < minimum }
      next
    else
      selected = test_array
      break
    end
  end

  selected.map { |n| n.round(2) }
end

def vote(author, permlink, power)
  tx = Radiator::Transaction.new(wif: ENV['STEEMHUNT_POSTING_KEY'])
  vote = {
    type: :vote,
    voter: 'steemhunt',
    author: author,
    permlink: permlink,
    weight: (power * 100).to_i
  }
  tx.operations << vote
  with_retry(3) do
    tx.process(true)
  end
end

def comment(author, permlink, rank)
  yesterday = Date.yesterday.strftime("%e %b %Y")
  msg = "### Congratulation! Your hunt was ranked in #{rank.ordinalize} place on #{yesterday} on Steemhunt.\n" +
    "We have upvoted your post for your contribution within our community.\n" +
    "Thanks again and look forward to seeing your next hunt!\n\n" +
    "Want to chat? Join us on:\n" +
    "* Discord: https://discord.gg/mWXpgks\n" +
    "* Telegram: https://t.me/joinchat/AzcqGxCV1FZ8lJHVgHOgGQ\n"

  tx = Radiator::Transaction.new(wif: ENV['STEEMHUNT_POSTING_KEY'])
  comment = {
    type: :comment,
    parent_author: author,
    parent_permlink: permlink,
    author: 'steemhunt',
    permlink: "re-#{permlink}-steemhunt",
    title: '',
    body: msg,
    json_metadata: {
      tags: ['steemhunt'],
      community: 'steemhunt',
      app: 'steemhunt/1.0.0',
      format: 'markdown'
    }.to_json
  }
  tx.operations << comment
  tx.process(true)
end

def run_and_retry_on_exception(cmd, tries: 0, max_tries: 3, delay: 10)
  tries += 1
  run_or_raise(cmd)
rescue SomeException => exception
  report_exception(exception, cmd: cmd)
  unless tries >= max_tries
    sleep delay
    retry
  end
end

def with_retry(limit)
  limit.times do |i|
    begin
      res = yield i
      if res.try(:error)
        SLogger.log res.error
        raise
      end

      return res
    rescue => e
      SLogger.log e
      raise e if i + 1 == limit
    end
    sleep(10)
  end
end

def get_bid_bot_ids
  # Disable bidbot filtering - REF: #discussion on Discord on 2018-04-30
  # JSON.parse(File.read("#{Rails.root}/db/bid_bot_ids.json"))
  []
end

def comment_already_voted?(comment, api)
  votes = with_retry(3) do
    api.get_content(comment['author'], comment['permlink'])['result']['active_votes']
  end

  votes.each do |vote|
    if vote['voter'] == 'steemhunt'
      return true
    end
  end

  return false
end

desc 'Voting bot'
task :voting_bot => :environment do |t, args|
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time

  logger = SLogger.new

  logger.log "Voting on daily post begin"
  posts = Post.where('created_at >= ? AND created_at < ?', yesterday, today).
               order('payout_value DESC').
               limit(MAX_POST_VOTING_COUNT).to_a

  logger.log "Total #{posts.size} posts found on #{yesterday.strftime("%e %b %Y")}", true

  api = Radiator::Api.new
  bid_bot_ids = get_bid_bot_ids
  review_comments = []
  moderators_comments =  []
  posts_to_skip = []
  posts_to_remove = []
  posts.each_with_index do |post, i|
    logger.log "@#{post.author}/#{post.permlink}"

    unless post.is_verified
      posts_to_remove << post.id
      post.update! created_at: Time.now # pass it over to the next date
      logger.log "--> REMOVE: Not yet verified"
      next
    end

    if post.is_active
      votes = with_retry(3) do
        api.get_content(post.author, post.permlink)['result']['active_votes']
      end

      # logger.log "----> #{votes.size} active votes returned"
      votes.each do |vote|
        if vote['voter'] == 'steemhunt'
          posts_to_skip << post.id
          logger.log "--> SKIP: Already voted"
          break # inner loop only
        elsif bid_bot_ids.include?(vote['voter'])
          posts_to_remove << post.id
          logger.log "--> REMOVE: Bitbot use detected: #{vote['voter']}"
          break # inner loop only
        end
      end
    else
      posts_to_remove << post.id
      logger.log "--> HIDDEN: still checks comments for moderators and review comments"
    end

    comments = with_retry(3) do
      api.get_content_replies(post.author, post.permlink)['result']
    end
    # logger.log "----> #{comments.size} comments returned"
    comments.each do |comment|
      # 1. Review comments
      if comment['body'] =~ /pros\s*:/i && comment['body'] =~ /cons\s*:/i
        should_skip = comment_already_voted?(comment, api)

        review_comments.push({ author: comment['author'], permlink: comment['permlink'], should_skip: should_skip })
        logger.log "--> #{should_skip ? 'SKIP' : 'FOUND'} Review comment: @#{comment['author']}/#{comment['permlink']}"
      end

      # 2. Moderator comments
      json_metadata = JSON.parse(comment['json_metadata']) rescue {}
      unless json_metadata['verified_by'].blank?
        if  User::MODERATOR_ACCOUNTS.include?(comment['author'])
          should_skip = comment_already_voted?(comment, api)
          moderators_comments.push({ author: comment['author'], permlink: comment['permlink'], should_skip: should_skip })
          logger.log "--> #{should_skip ? 'SKIP' : 'FOUND'} Moderator comment: @#{comment['author']}/#{comment['permlink']}"
        else
          logger.log "--> WTF!!!!! Moderator comment: @#{comment['author']}/#{comment['permlink']}"
        end
      end
    end # comments.each
  end # posts.each

  posts = posts.to_a.reject { |post| posts_to_remove.include?(post.id) }

  logger.log "== VOTING ON #{posts.size} POSTS ==", true

  vp_distribution = natural_distributed_array(posts.size)
  posts.each_with_index do |post, i|
    ranking = i + 1
    voting_power = vp_distribution[ranking - 1]

    logger.log "Voting on ##{ranking} (#{voting_power}%): @#{post.author}/#{post.permlink}"
    if posts_to_skip.include?(post.id)
      logger.log "--> SKIPPED_POST"
    else
      sleep(20)
      res = vote(post.author, post.permlink, voting_power)
      logger.log "--> VOTED_POST: #{res.result.try(:id) || res.error}"
      res = comment(post.author, post.permlink, ranking)
      logger.log "--> COMMENTED: #{res.result.try(:id) || res.error}"
    end
  end

  logger.log "== VOTING ON #{review_comments.size} REVIEW COMMENTS =="

  voting_power = (POWER_TOTAL_COMMENT / review_comments.size).round(2)
  voting_power = 100.0 if voting_power > 100
  review_comments.each do |comment|
    logger.log "Voting on review comment (#{voting_power}%): @#{comment[:author]}/#{comment[:permlink]}"
    if comment[:should_skip]
      logger.log "--> SKIPPED_REVIEW"
    else
      sleep(3)
      res = vote(comment[:author], comment[:permlink], voting_power)
      logger.log "--> VOTED_REVIEW: #{res.result.try(:id) || res.error}"
    end
  end

  logger.log "== VOTING ON #{moderators_comments.size} MODERATOR COMMENTS =="

  voting_power = (POWER_TOTAL_MODERATOR / moderators_comments.size).round(2)
  voting_power = 100.0 if voting_power > 100
  moderators_comments.each do |comment|
    logger.log "Voting on moderator comment (#{voting_power}%): @#{comment[:author]}/#{comment[:permlink]}"
    if comment[:should_skip]
      logger.log "--> SKIPPED_MODERATOR"
    else
      sleep(3)
      res = vote(comment[:author], comment[:permlink], voting_power)
      logger.log "--> VOTED_MODERATOR: #{res.result.try(:id) || res.error}"
    end
  end

  vp_left = with_retry(3) do
    api.get_accounts(['steemhunt'])['result'][0]['voting_power']
  end

  logger.log "Votings Finished, #{(vp_left / 100.0).round(2)}% VP left", true
end