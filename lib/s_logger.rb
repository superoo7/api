require 'discord'

class SLogger
  def self.log(text)
    if Rails.env.production?
      Discord.send(text)
    else
      puts text
    end
  end
end