#!/bin/bash

bundle check || bundle install

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

rails db:environment:set RAILS_ENV=$RAILS_ENV

rails db:drop db:create db:migrate db:seed 
rails s
# npm run --prefix ../web watch-css &
# npm run --prefix ../web start