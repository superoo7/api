require 'radiator'

class User < ApplicationRecord
  validates_presence_of :username
  validate :validate_eth_format
  has_many :hunt_transactions

  ADMIN_ACCOUNTS = ['steemhunt', 'tabris', 'project7']
  MODERATOR_ACCOUNTS = [
    'tabris', 'project7',
    'teamhumble', 'folken', 'urbangladiator', 'chronocrypto', 'dayleeo', 'fknmayhem', 'jayplayco', 'bitrocker2020', 'joannewong',
    'geekgirl', 'playitforward'
  ]
  GUARDIAN_ACCOUNTS = [
    'folken', 'fknmayhem'
  ]

  scope :whitelist, -> {
    where('last_logged_in_at >= ?', Time.zone.today.to_time).
    where.not(encrypted_token: '').where('reputation >= ?', 35).
    where('blacklisted_at IS NULL OR blacklisted_at < ?', 1.month.ago)
  }

  def dau?
    last_logged_in_at > Time.zone.today.to_time
  end

  def dau_yesterday?
    last_logged_in_at > Time.zone.yesterday.to_time
  end

  def blacklist?
    !blacklisted_at.nil? && blacklisted_at > 1.month.ago
  end

  def admin?
    ADMIN_ACCOUNTS.include?(username)
  end

  def moderator?
    MODERATOR_ACCOUNTS.include?(username)
  end

  def guardian?
    GUARDIAN_ACCOUNTS.include?(username)
  end

  # Ported from steem.js
  # Basic rule: ((Math.log10(raw_score) - 9) * 9 + 25).floor
  def self.rep_score(raw_score)
    return 0 if raw_score.to_i == 0

    raw_score = raw_score.to_i
    neg = raw_score < 0 ? -1 : 1
    raw_score = raw_score.abs
    leading_digits = raw_score.to_s[0..3]
    log = Math.log10(leading_digits.to_i)
    n = raw_score.to_s.length - 1
    out = n + log - log.to_i
    out = 0 if out.nan?
    out = [out - 9, 0].max
    out = neg * out * 9 + 25

    out.to_i
  end

  def validate!(token)
    res = User.fetch_data(token)

    if res['user'] == self.username
      self.update!(
        encrypted_token: Digest::SHA256.hexdigest(token),
        reputation: User.rep_score(res['account']['reputation']),
        vesting_shares: res['account']['vesting_shares'].to_f
      )

      true
    else
      false
    end
  end

  def voting_weight
    return 0 if !dau? || reputation < 35 # only whitelist
    return 0 if blacklist? # no blacklist for 1 month

    weight = if reputation >= 60
      0.03
    elsif reputation >= 55
      0.02
    elsif reputation >= 45
      0.01
    else
      0.005
    end

    weight * diversity_score
  end

  def hunt_score_by(weight)
    return 0 if weight <= 0 # no down-votings

    voting_weight * weight
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

  # MARK: - Diversity Score

  def votee
    Post.from('posts, json_array_elements(posts.valid_votes) v').
      where("v->>'voter' = ?", username).group(:author).count
  end

  def votee_weight
    Post.from('posts, json_array_elements(posts.valid_votes) v').
      where("v->>'voter' = ?", username).group(:author).sum("(v#>>'{percent}')::integer")
  end

  # weighted version of `voted users count / voting count`
  # range from 0.0 - 1.0
  # if a user voted 100 times (with the same weight to all):
  # - only 1 receiver => 0.01
  # - 90 receivers => 0.9
  def diversity_score
    return cached_diversity_score if cached_diversity_score >= 0 && diversity_score_updated_at && diversity_score_updated_at > 24.hours.ago

    counts = votee
    weights = votee_weight

    voting_count = 0
    total_weight = 0
    weighted_receiver_count = 0
    counts.each do |id, count|
      voting_count += count
      weighted_receiver_count += (weights[id] / count.to_f)
      total_weight += weights[id]
    end

    avg_voting_count_per_user = voting_count / counts.count.to_f

    # users on day 1 always have 1.0 weight on diversity score
    # because they can only vote once per every users anyway
    # - minimize fresh account abusing by make threshold avg_voting_count_per_user to 1.1
    # - also reduce score for fresh accounts
    score = if avg_voting_count_per_user <= 1.1 || voting_count < 20
      0.1
    elsif voting_count < 50
      0.5 * weighted_receiver_count / total_weight.to_f
    else
      weighted_receiver_count / total_weight.to_f
    end

    # higher weight if user spent 50 full votes & maintained a good diversity
    # exclude dust thresholds (< 500 SP)
    if score > 0.64 && weighted_receiver_count > 500000 && vesting_shares > 1000000
      score *= 1.5
    end

    self.cached_diversity_score = score
    self.diversity_score_updated_at = Time.now
    self.save!

    self.cached_diversity_score
  end
end
