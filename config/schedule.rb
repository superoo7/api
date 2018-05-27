env :MAILTO, 'sydneyitguy@gmail.com'
set :output, '/srv/web/steemhunt/shared/log/cron.log'

ROOT_DIR = '/srv/web/steemhunt/current'
RAKE_PATH = '/home/updatebot/.rbenv/shims/bundle exec rake'

every :day, at: '12:01am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[1] voting_bot"
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[1] && RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[8]"
end

every :day, at: ['04:00am', '07:00am', '10:00am', '01:00pm', '04:00pm', '07:00pm', '10:00pm'] do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} sync_posts[0]"
end

every :day, at: '5:00am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} daily_post"
end

every :day, at: '05:02am' do
  command "cd #{ROOT_DIR};RAILS_ENV=#{environment} #{RAKE_PATH} dump"
end
