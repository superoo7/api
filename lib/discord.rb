class Discord
  def initialize(channel = 'bot-log')
    @web_hook = case channel
      when 'reward-log'
        ENV['REWARD_WEB_HOOK']
      when 'voting-log'
        ENV['VOTING_WEB_HOOK']
      else
        ENV['DISCORD_WEB_HOOK']
      end
  end

  def send(content)
    payload = {
      username: 'Steemhunt',
      content: content,
    }.to_json
    puts "---> DISCORD payload: #{payload}" and return unless Rails.env.production?

    result = `curl -s -S -H \"Content-Type: application/json\" -X POST -d '#{payload}' #{@web_hook}`

    # When rate limited
    unless result.empty?
      begin
        result = JSON.parse(result)
        if result['retry_after']
          wait_seconds = 1 + result['retry_after'].to_f / 1000
          puts "Rate limitted, retry after #{wait_seconds}s"
          sleep(wait_seconds)
          send(content)
        else
          puts "UNKNOWN ERROR - #{result}"
        end
      rescue
        puts "ERROR on parsing: #{result}"
      end
    end
  end
end