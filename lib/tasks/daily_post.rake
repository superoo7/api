require 'radiator'
require 's_logger'
require 'utils'

desc 'Daily Post'
task :daily_post => :environment do |t, args|
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time

  date = yesterday.strftime("%e %b %Y")
  title = "Daily Top 10 Hunts on Steemhunt (#{date})"
  SLogger.log "Start posting - #{title}"

  posts = Post.where('created_at >= ? AND created_at < ?', yesterday, today).
              where(is_active: true).
              order('hunt_score DESC')
  total_count = posts.count
  total_generated = posts.sum(&:payout_value)
  posts = posts.first(10)

  tag_count = {}
  posts.each do |post|
    post.tags.each do |tag|
      next if tag =~ /kr/

      if tag_count[tag].nil?
        tag_count[tag] = 1
      else
        tag_count[tag] += 1
      end
    end
  end
  tags = ['steemhunt'] + tag_count.sort_by {|k,v| v}.reverse.map(&:first).first(4)

  body = "Hello hunters!\n\n" +
    "Yesterday, there were #{total_count} products, and $#{formatted_number total_generated} SBD hunter’s rewards were generated.\n\n" +
    "# Top 10 Hunts on #{date}\n" +
    "Take a look at the top 10 hunted products yesterday for your daily dose of inspiration 😎\n"

  posts.each_with_index do |post, i|
    body += "### [#{i + 1}. #{post.title}](#{post.steemhunt_url})\n" +
      "#{post.tagline}\n" +
      "![](#{post.images.first['link']})\n" +
      ">@#{post.author} · #{post.valid_votes.count} votes and #{post.children} comments\n" +
      "HUNT Score: #{formatted_number post.hunt_score} (Pending payout: $#{formatted_number post.payout_value} SBD)\n"
  end

  body += "---\n" +
    "<center><br/>![Steemhunt.com](https://steemitimages.com/DQmVTsk8LrQXcDekbqJTFLCYoP1atnfac1T4X4veVHBhkWJ/image.png)<br/>\n" +
    "## Steemhunt\n" +
    "A place where you can dig products and earn STEEM.\n" +
    "[Steemhunt.com](https://steemhunt.com)\n\n" +
    "*Join our [Telegram](https://t.me/joinchat/AzcqGxCV1FZ8lJHVgHOgGQ) or [Discord](https://discord.gg/mWXpgks) channel for feedbacks & questions.*\n" +
    "*Support Steemhunt with Steem Power Delegation:\n" +
    "[500 SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=500%20SP) |" +
    "[1000 SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=1000%20SP) |" +
    "[5000 SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=5000%20SP) |" +
    "[10K SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=10000%20SP) |" +
    "[20K SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=20000%20SP) |" +
    "[50K SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=50000%20SP) |" +
    "[100K SP](https://steemconnect.com/sign/delegateVestingShares?delegator=&delegatee=steemhunt&vesting_shares=100000%20SP)*\n" +
    "*More information about our Sponsor program is [here](https://steemit.com/steemhunt/@steemhunt/introducing-incentives-for-steemhunt-sponsors)*\n\n" +
    "*Support Steemhunt by following our [curation trail](https://steemauto.com/dash.php?trail=steemhunt&i=1)*" +
    "</center>"

  tx = Radiator::Transaction.new(wif: ENV['STEEMHUNT_POSTING_KEY'])
  comment = {
    type: :comment,
    parent_permlink: 'steemhunt',
    parent_author: '',
    author: 'steemhunt',
    permlink: title.parameterize,
    title: title,
    body: body,
    json_metadata: {
      tags: tags,
      image: posts.map(&:images).map(&:first).map { |i| i['link'] },
      users: posts.map(&:author),
      links: posts.map(&:url),
      community: 'steemhunt',
      app: 'steemhunt/1.0.0',
      format: 'markdown'
    }.to_json
  }

  tx.operations << comment
  tx.process(true)

  SLogger.log "Post succeeded"
end