require 'net/http'
require 'json'

class Post < ApplicationRecord
  validates_presence_of :author, :url, :title, :tagline, :images
  validates_format_of :url, with: /\A(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,})(.*)\z/i
  validates_format_of :permlink, with: /\A[\d\-a-z]+\z/i, allow_blank: false # digits, dashes, letters only (no underbar)
  validates_uniqueness_of :url

  def self.data_from_steem(author, permlink)
    uri = URI("https://steemit.com/steemhunt/@#{author}/#{permlink}.json")
    response = Net::HTTP.get(uri)
    JSON.parse(response)['post']
  end

  def sync!
    json = self.class.data_from_steem(author, permlink)
    self.active_votes = json['active_votes']
    self.payout_value = json['total_payout_value'].to_f + json['curator_payout_value'].to_f + json['pending_payout_value'].to_f
    self.children = json['children']
    self.save!
  end

  def active?
    is_active
  end
end
