class HuntTransaction < ApplicationRecord
  belongs_to :user
  validates_presence_of :user_id, :receiver, :amount, :memo

  def self.reward_sponsor(username, amount, week)
    user = User.find_by(username: username)
    user = User.create!(username: username, encrypted_token: '') unless user

    self.create!(
      sender_id: 0, # steemhunt
      receiver_id: user.id,
      amount: amount,
      memo: "Delegation sponsor payout on week #{week}"
    )
  end
end
