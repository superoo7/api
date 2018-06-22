users = [
]

users.each do |u|
  user = User.find_by(username: u)
  if user.nil?
    puts "Not a user: #{u}"
  elsif user.blacklist?
    puts "Already blacklisted: #{u}"
  else
    user.update blacklisted_at: Time.now
    puts "Blacklisted: https://steemit.com/@#{u}"
  end
end

HuntTransaction.reward_reporter! '', 500
