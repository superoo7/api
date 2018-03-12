desc 'Dump database and Redis'
task :dump => :environment do |t, args|
  month_ago_backup = 1.month.ago.strftime('%Y-%m')
  timestamp = Time.now.strftime('%Y-%m-%d-%H-%M-%S')
  system("rm /srv/backup/db/steemhunt-#{month_ago_backup}-*.sql*")
  system("/usr/lib/postgresql/9.5/bin/pg_dump -d steemhunt > /srv/backup/db/steemhunt-#{timestamp}.sql")
  system("gzip /srv/backup/db/steemhunt-#{timestamp}.sql")
  system("chmod 640 /srv/backup/db/steemhunt-#{timestamp}.sql.gz")
  puts ' -- Steemhunt database backup complete'

  system("rm /srv/backup/redis/redis-#{month_ago_backup}-*.rdb*")
  system("sudo cp /var/lib/redis/dump.rdb /srv/backup/redis/redis-#{timestamp}.rdb")
  system("sudo gzip /srv/backup/redis/redis-#{timestamp}.rdb")
  system("sudo chown updatebot /srv/backup/redis/redis-#{timestamp}.rdb.gz")
  puts ' -- Steemhunt Redis backup complete'

  puts 'Finished database and Redis dump'
end
