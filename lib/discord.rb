require 's_logger'

class Discord
  def self.send(content)
    payload = {
      username: 'Steemhunt',
      content: content,
    }.to_json


    puts "---> DISCORD payload: #{payload}" and return unless Rails.env.production?

    result = `curl -s -S -H \"Content-Type: application/json\" -X POST -d '#{payload}' #{ENV['DISCORD_WEB_HOOK']}`

    # When rate limited
    unless result.empty?
      begin
        result = JSON.parse(result)
        if result['retry_after']
          wait_seconds = result['retry_after'].to_f / 1000
          SLogger.send "Rate limitted, retry after #{wait_seconds}s"
          sleep(wait_seconds + 10)
          self.send(content)
        end
      rescue
        SLogger.send "ERROR on parsing: #{result}"
      end
    end
  end
end