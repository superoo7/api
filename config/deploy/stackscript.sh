# MARK: - System updates
sudo update-locale LANG=en_US.UTF-8 LANGUAGE= LC_CTYPE="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" LC_MONETARY="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" LC_PAPER="en_US.UTF-8" LC_NAME="en_US.UTF-8" LC_ADDRESS="en_US.UTF-8" LC_TELEPHONE="en_US.UTF-8" LC_MEASUREMENT="en_US.UTF-8" LC_IDENTIFICATION="en_US.UTF-8" LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8

sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove

sudo dpkg-reconfigure tzdata

# MARK: - Users & SSH

USER_NAME="updatebot"
sudo adduser $USER_NAME
sudo adduser $USER_NAME sudo
sudo su $USER_NAME
cd && mkdir .ssh

sudo cp ~ubuntu/.ssh/authorized_keys ~updatebot/.ssh/
sudo chown updatebot ~/.ssh/*;sudo chgrp updatebot ~/.ssh/*;chmod 600 ~/.ssh/authorized_keys

sudo vim /etc/ssh/sshd_config # change port to 2222
sudo service sshd restart

# MARK: - nginx & git
nginx=stable # use nginx=development for latest development version
sudo add-apt-repository ppa:nginx/$nginx;sudo apt-get update;sudo apt-get install nginx git

# MARK: -- rbenv & ruby
sudo apt-get install -y build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev gcc libgsl0-dev
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
echo 'eval "$(rbenv init -)"' >> ~/.profile
exec $SHELL -l
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
sudo apt-get install libffi-dev # https://github.com/sstephenson/ruby-build/wiki#build-failure-of-fiddle-with-ruby-220
rbenv install 2.4.3
rbenv rehash && rbenv global 2.4.3
sudo ln -s ~/.rbenv/shims/ruby /usr/local/bin/ruby;sudo ln -s ~/.rbenv/shims/gem /usr/local/bin/gem
gem update --system && gem install bundler

# MARK: - Deploy
sudo chown updatebot /srv/ && chgrp updatebot /srv
mkdir /srv/web/;mkdir /srv/web/steemhunt;mkdir /srv/web/steemhunt/releases
# Puma shared directories
mkdir /srv/web/steemhunt/shared;mkdir /srv/web/steemhunt/shared/pids;mkdir /srv/web/steemhunt/shared/log;mkdir /srv/web/steemhunt/shared/sockets


# MARK: - Postgres
sudo apt-get install postgresql libpq-dev

# DB user
sudo su postgres
PG_DBNAME=steemhunt
PG_UNAME=steemhunt
psql -d postgres -c "CREATE USER $PG_UNAME;"
psql -d postgres -c "DROP DATABASE $PG_DBNAME;"

psql -d postgres -c "ALTER USER $PG_UNAME CREATEDB;"
psql -d postgres -c "ALTER USER $PG_UNAME WITH SUPERUSER;"

# Enable updatebot to run psql
psql -d postgres -c "CREATE USER updatebot"
psql -d postgres -c "ALTER USER updatebot WITH SUPERUSER;"

# TO avaoid LC_CTYPE setting requires encoding "LATIN1" error
psql
update pg_database set datistemplate=false where datname='template1';
drop database template1;
create database template1 with owner=postgres encoding='UTF-8' lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;
update pg_database set datistemplate=true where datname='template1';

psql -d postgres -c "ALTER USER $PG_UNAME WITH PASSWORD 'DB_PASSWORD';"
exit

sudo vim /etc/postgresql/9.5/main/pg_hba.conf

# Add following lines on top
local   all             steemhunt                               trust
host    all             steemhunt       127.0.0.1/32            trust
host    all             steemhunt       ::1/128                 trust

# Test peer auth
sudo su postgres
psql -c "SELECT pg_reload_conf();"
exit
psql -U $PG_UNAME -d postgres -c "CREATE DATABASE $PG_DBNAME;"


# Setup SSL via Let's Encrypt
sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
/opt/letsencrypt/letsencrypt-auto --server https://acme-v01.api.letsencrypt.org/directory --help --debug

sudo vim /etc/nginx/sites-available/steemhunt
# Start with this simple setup
```
server {
    listen 80 deferred;
    server_name steemhunt.com *.steemhunt.com;

    root /srv/web/steemhunt/current/public;
    location ~ /.well-known {
        allow all;
    }
}
```
sudo nginx -s reload

/opt/letsencrypt/letsencrypt-auto certonly -a webroot --webroot-path=/srv/web/steemhunt/current/public -d steemhunt.com -d www.steemhunt.com -d api.steemhunt.com

sudo vim /etc/nginx/sites-available/steemhunt
# Add following lines
```
    ssl_certificate /etc/letsencrypt/live/steemhunt.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/steemhunt.com/privkey.pem;
```

# Generate Strong Diffie-Hellman Group
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

service nginx restart

# Setup auto-renewal - monthly cronjob
sudo crontab -e

```
0 0 1 * * /opt/letsencrypt/letsencrypt-auto renew >> /srv/web/steemhunt/current/log/le-renew.log
0 0 1 * * /etc/init.d/nginx reload
```

# Setup swapfile
sudo su
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab # persist on reboot
free -m

sudo sysctl vm.swappiness=10
echo "vm.swappiness = 10" >> /etc/sysctl.conf  # persist on reboot
cat /proc/sys/vm/swappiness

sudo sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf  # persist on reboot
cat /proc/sys/vm/vfs_cache_pressure

