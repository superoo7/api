# Steemhunt Back-end

## Stacks
- Ruby 2.4
- Rails 5
- Nginx / Puma
- PostgreSQL

## Development setup

### DB Preparation

### Install
First install rbenv and ruby
```
brew install rbenv
brew install ruby-build
rbenv install 2.4.2
```

If you don't have PostgresSQL or Node installed on your machine, install it via
```
brew install postgresql node
```

Then prepare your dev database:
```
PG_UNAME=steemhunt
psql -d postgres -c "CREATE USER $PG_UNAME;"
psql -d postgres -c "ALTER USER $PG_UNAME CREATEDB;"
psql -d postgres -c "ALTER USER $PG_UNAME WITH SUPERUSER;"
```

Then clone the api repo on 
`your_path/steemhunt/api`
and web repo on 
`your_path/steemhunt/web`

On api repo, install gems
```
gem install bundler
bundle install
```

then migrate database
```
bundle exec rails db:drop db:create db:migrate db:seed
```

Now you finished installation.

You can start both api and web server by running 
```
bundle exec rails start
```
