class User < ApplicationRecord
  validates_presence_of :username
  validate :validate_eth_format
  has_many :hunt_transactions

  ADMIN_ACCOUNTS = ['steemhunt', 'tabris', 'project7']
  MODERATOR_ACCOUNTS = [
    'tabris', 'project7',
    'teamhumble', 'folken', 'urbangladiator', 'chronocrypto', 'dayleeo', 'fknmayhem', 'jayplayco', 'bitrocker2020', 'joannewong'
  ]

  scope :whitelist, -> {
    where.not(encrypted_token: '').where('reputation >= ?', 35).
    where('blacklisted_at IS NULL OR blacklisted_at < ?', 1.month.ago)
  }

  def first_logged_in?
    !encrypted_token.blank?
  end

  def dau?
    first_logged_in? && updated_at > 1.day.ago
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

  def hunt_score_by(weight)
    return 0 if weight <= 0 # no down-votings
    return 0 if !dau? || reputation < 35 # only whitelist
    return 0 if (!blacklisted_at.nil? && blacklisted_at >= 1.month.ago) # no blacklist for 1 month

    ratio = if reputation >= 60
      0.03
    elsif reputation >= 55
      0.02
    elsif reputation >= 45
      0.01
    else
      0.005
    end

    weight * ratio
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
