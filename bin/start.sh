#!/bin/bash

bundle check || bundle install

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

# Set dev mode
rails db:environment:set RAILS_ENV=development

# Reset db
rails db:drop db:create db:migrate db:seed 

# Start rails
rails s -p $PORT -b 0.0.0.0