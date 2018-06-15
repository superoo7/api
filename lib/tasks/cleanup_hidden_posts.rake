require 's_logger'

desc 'Cleanup de-listed posts'
task :cleanup_hidden_posts => :environment do |t, args|
  count = Post.where('created_at < ?', Time.zone.today.to_time - 8.days).
               where(is_active: false).delete_all

  logger = SLogger.new
  logger.log "==========\nDELETED #{count} de-listed posts from 8 days ago\n==========", true
end