class HuntTransaction < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User', optional: true
  validates_presence_of :sender_id, :amount, :memo
  validate :validate_receiver, :validate_eth_format

  SPONSOR_PAYOUT_MEMO_PREFIX = 'Steemhunt weekly HUNT reward from the sponsor program: week '

  def validate_receiver
    if receiver_id.blank? && eth_address.blank?
      errors.add(:receiver_id, "Receiver cannot be empty")
    elsif !receiver_id.blank? && !eth_address.blank?
      errors.add(:eth_address, "Only one of internal or external receiver can be assigned")
    end
  end

    def validate_eth_format
      unless eth_address.blank?
        errors.add(:eth_address, "Wrong format") if eth_address.size != 42 || !eth_address.downcase.start_with?('0x')
      end

      unless eth_tx_hash.blank?
        errors.add(:eth_tx_hash, "Wrong format") if eth_tx_hash.size != 66 || !eth_tx_hash.downcase.start_with?('0x')
      end
    end

  def self.reward_sponsor!(username, amount, week)
    return if amount == 0

    user = User.find_by(username: username)
    user = User.create!(username: username, encrypted_token: '') unless user

    self.send!(0, amount, user.id, nil, "#{SPONSOR_PAYOUT_MEMO_PREFIX}#{week}")
  end

  def self.send!(sender_id, amount, receiver_id = nil, eth_address = nil, memo = nil)
    return if amount == 0

    ActiveRecord::Base.transaction do
      self.create!(
        sender_id: sender_id,
        receiver_id: receiver_id,
        eth_address: eth_address,
        amount: amount,
        memo: memo
      )

      sender = User.find(sender_id)
      sender.update!(hunt_balance: sender.hunt_balance - amount)
      unless receiver_id.blank?
        receiver = User.find(receiver_id)
        receiver.update!(hunt_balance: receiver.hunt_balance + amount)
      end
    end

    unless eth_address.blank?
      # TODO: ETH Transaction

      # TODO: Rollback on errors - should be in a separate transaction
    end
  end
end
