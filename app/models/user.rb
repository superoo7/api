class User < ApplicationRecord
  validates_presence_of :username, :encrypted_token
end
