class Discord
  def self.send(content)
    payload = {
      username: 'Steemhunt',
      content: content,
    }.to_json

    if Rails.env.production?
      system("curl -s -S -H \"Content-Type: application/json\" -X POST -d '#{payload}' #{ENV['DISCORD_WEB_HOOK']} > /dev/null")
    else
      puts "---> DISCORD payload: #{payload}"
    end
  end
end