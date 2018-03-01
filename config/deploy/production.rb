role :app, 'steemhunt.com:2222'
role :web, 'steemhunt.com:2222'
role :db, 'steemhunt.com:2222', primary: true

set :ssh_options, {
  user: 'updatebot',
  keys: %w(~/.ssh/seb-aws.pem),
  forward_agent: true
}
