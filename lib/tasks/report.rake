desc 'Report'
task :report, [:days] => :environment do |t, args|
  days = args[:days].to_i

  (1..days).each do |day|
    today = Time.zone.today.to_time
    posts = Post.where('created_at >= ? AND created_at < ?', today - day.days, today - (day - 1).days)

    puts "#{(today - (day - 1).days).strftime('%Y-%m-%d')}: #{posts.count} posts, $#{posts.sum(:payout_value)}"
  end
end