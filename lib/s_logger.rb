require 'discord'

class SLogger
  BLOCK_SIZE = 1000

  def initialize
    @stack = ''
  end

  # Stack up logs and send in a bulk to avoid Discord rate limit
  def log(text, flush = false, newline = true)
    unless Rails.env.production?
      if newline
        puts text
      else
        print text
      end
      return
    end

    if newline
      @stack += "#{text}\n"
    else
      @stack += "#{text}"
    end

    if @stack.size > BLOCK_SIZE || flush
      Discord.send(@stack)
      @stack = ''
    end
  end

  def self.log(text)
    unless Rails.env.production?
      puts text
      return
    end

    Discord.send(text)
  end
end