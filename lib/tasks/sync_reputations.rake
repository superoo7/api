require 'radiator'

desc 'Sync Reputations'
task :sync_reputations => :environment do |t, args|
  api = Radiator::Api.new
  usernames = User.all.pluck(:username)

  puts "Sync reputations of #{usernames.size} users"

  usernames.each_slice(1000).each_with_index do  |block, i|
    puts "= Fetch block #{i + 1} - #{block.size} / #{usernames.size}"
    users = api.get_accounts(block)['result']
    users.each do |u|
      user = User.find_by(username: u['name'])
      user.update!(reputation: User.rep_score(u['reputation']))
      puts "--> @#{user.username} => #{user.reputation}"
    end
  end
end