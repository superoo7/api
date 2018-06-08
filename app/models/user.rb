class User < ApplicationRecord
  validates_presence_of :username
  validate :validate_eth_format
  has_many :hunt_transactions

  ADMIN_ACCOUNTS = ['steemhunt', 'tabris', 'project7']
  MODERATOR_ACCOUNTS = [
    'tabris', 'project7',
    'teamhumble', 'folken', 'urbangladiator', 'chronocrypto', 'dayleeo', 'fknmayhem', 'jayplayco', 'bitrocker2020', 'joannewong'
  ]

  def first_logged_in?
    !encrypted_token.blank?
  end

  def wau?
    updated_at > 7.days.ago
  end

  def dau?
    updated_at > 1.day.ago
  end

  def admin?
    ADMIN_ACCOUNTS.include?(username)
  end

  def moderator?
    MODERATOR_ACCOUNTS.include?(username)
  end

  def validate!(token)
    res = User.fetch_data(token)

    if res['user'] == self.username
      self.update!(
        encrypted_token: Digest::SHA256.hexdigest(token),
        reputation: ((Math.log10(res['account']['reputation'].to_i) - 9) * 9 + 25).floor # raw rep score to human friendly
      )

      true
    else
      false
    end
  end

  def level
    return 0 unless first_logged_in? && reputation > 35

    if hc_score > 100000
      5
    elsif hc_score > 30000
      4
    elsif hc_score > 10000
      3
    elsif hc_score > 3000
      2
    else
      1
    end
  end

  def validate_eth_format
    unless eth_address.blank?
      errors.add(:eth_address, "Wrong format") if eth_address.size != 42 || !eth_address.downcase.start_with?('0x')
    end
  end

  # Fetch user JSON data from SteemConnect
  # Only used when we need to double check current user's token
  def self.fetch_data(token)
    retries = 0

    begin
      uri = URI.parse('https://v2.steemconnect.com/api/me')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      header = {
        'Content-Type' =>'application/json',
        'Authorization' => token
      }
      req = Net::HTTP::Post.new(uri.path, header)
      res = https.request(req)
      body = JSON.parse(res.body)

      raise res.body if body['user'].blank?

      body
    rescue => e
      retry if (retries += 1) < 3

      { error: e.message }
    end
  end
end
