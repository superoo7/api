# Steemhunt Back-end

## Stacks
- Ruby 2.4
- Rails 5
- Nginx / Puma
- PostgreSQL

## Development setup

### DB Preparation
```
PG_UNAME=steemhunt
psql -d postgres -c "CREATE USER $PG_UNAME;"
psql -d postgres -c "ALTER USER $PG_UNAME CREATEDB;"
psql -d postgres -c "ALTER USER $PG_UNAME WITH SUPERUSER;"

rails db:drop db:create db:migrate db:seed
```

### Install
```
brew install rbenv
brew install ruby-build
rbenv install 2.4.2
gem install bundler
bundle install
```