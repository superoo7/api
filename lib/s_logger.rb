require 'discord'

class SLogger
  BLOCK_SIZE = 1000

  def initialize
    @stack = ''
  end

  # Stack up logs and send in a bulk to avoid Discord rate limit
  def log(text, flush = false)
    puts text and return unless Rails.env.production?

    @stack += "#{text}\n"

    if @stack.size > BLOCK_SIZE || flush
      Discord.send(@stack)
      @stack = ''
    end
  end

  def self.log(text)
    puts text and return unless Rails.env.production?

    Discord.send(text)
  end
end