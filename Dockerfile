FROM ruby:2.4
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN gem install bundler
RUN mkdir /steemhunt
WORKDIR /steemhunt
COPY ./Gemfile /steemhunt/Gemfile
COPY ./Gemfile.lock /steemhunt/Gemfile.lock
RUN bundle install
COPY . /steemhunt
EXPOSE 3001