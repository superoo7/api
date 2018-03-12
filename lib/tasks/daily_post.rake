require 'radiator'

desc 'Daily Post'
task :daily_post => :environment do |t, args|
  today = Time.zone.today.to_time
  yesterday = (today - 1.day).to_time

  date = yesterday.strftime("%b %e, %Y")
  title = "Daily Top 10 Hunts on Steemhunt (#{date})"
  puts "Start posting - #{title}"

  posts = Post.where('created_at >= ? AND created_at < ?', yesterday, today).
              where(is_active: true).
              order('payout_value DESC')
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
    "Yesterday, there were #{total_count} products, and $#{total_generated} SBD hunter’s rewards were generated.\n\n" +
    "# Top 10 Hunts on March 11, 2018\n" +
    "Take a look at the top 10 hunted products yesterday for your daily dose of inspiration 😎\n"

  posts.each_with_index do |post, i|
    body += "### [#{i + 1}. #{post.title}](#{post.url})\n" +
      "#{post.tagline}\n" +
      "![](#{post.images.first['link']})\n" +
      ">@#{post.author} · #{post.active_votes.count} votes and #{post.children} comments\n" +
      "Pending payout: $#{post.payout_value} SBD\n"
  end

  body += "---\n" +
    "<center><br/>![Steemhunt.com](https://steemitimages.com/DQmVTsk8LrQXcDekbqJTFLCYoP1atnfac1T4X4veVHBhkWJ/image.png)<br/>\n" +
    "## Steemhunt\n" +
    "A place where you can dig products and earn STEEM.\n" +
    "[Steemhunt.com](https://steemhunt.com)\n" +
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
      app: 'steemhunt',
      format: 'markdown'
    }.to_json
  }

  tx.operations << comment
  tx.process(true)

  puts "Post succeeded"
end