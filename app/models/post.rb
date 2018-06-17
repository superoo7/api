require 'net/http'
require 'json'

class Post < ApplicationRecord
  validates_presence_of :author, :url, :title, :tagline, :images
  validates_format_of :url, with: /\A(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,})(.*)\z/i, message: 'Invalid URL format. Please include http or https at the beginning.'
  validates_format_of :permlink, with: /\A[\d\-a-z]+\z/i, allow_blank: false # digits, dashes, letters only (no underbar)
  validates_uniqueness_of :url, message: '- The product has already posted'
  validates_uniqueness_of :author, scope: :permlink, message: '- The product has already posted'

  # TODO_ABV: Uncomment for efficiency
  before_update :calculate_hunt_score#, if: :active_votes_changed?

  # NOTE: JSON structure
  # - active_votes: { "voter": "tabris", "weight": 645197, "rshares": "401660828088", "percent": 10000, "reputation": "7112685098931", "time": "2018-02-16T20:14:48" }
  # - valid_votes: { "voter": "tabris", "percent": 10000, "score": 3.0 }
  def calculate_hunt_score
    return if self.active_votes.blank?

    # freeze hunt_score after payout ends (when our sync task for day 8 finishes)
    return if self.created_at < Time.zone.today.to_time

    voters = self.active_votes.map { |v| v['voter'] }
    valid_voters = {}
    User.whitelist.where(username: voters).each do |u|
      valid_voters[u.username] = u unless u.username == self.author # remove self votings
    end

    return if valid_voters.size == 0

    self.hunt_score = 0
    self.valid_votes = []
    self.active_votes.each do |v|
      user = valid_voters[v['voter']]
      next if user.nil?
      next if v['percent'] <= 0

      score = user.hunt_score_by(v['percent'] / 100.0)
      self.hunt_score += score
      self.valid_votes << { 'voter' => v['voter'], 'percent' => v['percent'], 'score' => score }
      # puts "+ #{user.hunt_score_by(v['percent'] / 100.0)} by #{v['voter']}"
    end
  end

  def self.data_from_steem(author, permlink)
    uri = URI("https://steemit.com/steemhunt/@#{author}/#{permlink}.json")
    response = Net::HTTP.get(uri)
    JSON.parse(response)['post']
  end

  def sync!(json = nil)
    json ||= self.class.data_from_steem(author, permlink)
    self.active_votes = json['active_votes']
    self.payout_value = json['total_payout_value'].to_f + json['curator_payout_value'].to_f + json['pending_payout_value'].to_f
    self.children = json['children']
    self.save!
  end

  def key
    "@#{author}/#{permlink}"
  end

  def steemhunt_url
    "https://steemhunt.com/#{key}"
  end

  def active?
    is_active
  end
end
