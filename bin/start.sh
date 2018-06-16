#!/bin/bash

bundle check || bundle install

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

# bundle exec rails db:drop db:create db:migrate db:seed &&
bundle exec rails start -p 3000 -b 0.0.0.0 
# npm run --prefix ../web watch-css &
# npm run --prefix ../web start