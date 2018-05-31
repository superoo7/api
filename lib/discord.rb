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
          puts "Rate limitted, retry after #{wait_seconds}s"
          sleep(wait_seconds + 1)
          self.send(content)
        else
          puts "UNKNOWN ERROR - #{result}"
        end
      rescue
        puts "ERROR on parsing: #{result}"
      end
    end
  end
end