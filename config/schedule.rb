env :MAILTO, 'sydneyitguy@gmail.com'
set :output, '/srv/web/steemhunt/shared/log/cron.log'

ROOT_DIR = '/srv/web/steemhunt/current'
RAKE_PATH = '/home/updatebot/.rbenv/shims/bundle exec rake'

every :day, at: '12:01am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} reward_voters"
end

every :day, at: '12:30am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[1] voting_bot && " +
    "RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[1] && RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[8]"
end

every '0 4-23 * * *' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[0]"
end

every :day, at: '4:00am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} cleanup_hidden_posts"
end

every :day, at: '5:00am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} daily_post"
end

every :day, at: '06:00am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} dump"
end
