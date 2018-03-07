class User < ApplicationRecord
  validates_presence_of :username, :encrypted_token

  def admin?
    ['steemhunt', 'tabris', 'project7'].include?(username)
  end
end
