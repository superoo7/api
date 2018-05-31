require 'utils'

class HuntTransaction < ApplicationRecord
  validates_presence_of :amount, :memo
  validate :validate_sender_and_receiver, :validate_eth_format
  validates :memo, length: { maximum: 255 }

  SPONSOR_REWARD_MEMO_PREFIX = 'Weekly reward for delegation sponsor - week ' # + num
  VOTING_REWARD_MEMO_PREFIX = 'Daily reward for voting contribution - ' # + formatted date (%e %b %Y)
  RESTEEM_REWARD_MEMO_PREFIX = 'Daily reward for resteem contribution - ' # + formatted date (%e %b %Y)

  def validate_sender_and_receiver
    if sender.blank? && receiver.blank?
      errors.add(:receiver, "one side of transaction should be in off-chain")
    end

    if sender.blank? && eth_address.blank?
      errors.add(:sender, "cannot be empty")
    elsif !sender.blank? && !eth_address.blank?
      errors.add(:eth_address, "Only one of internal or external receiver can be assigned")
    end

    if receiver.blank? && eth_address.blank?
      errors.add(:receiver, "cannot be empty")
    elsif !receiver.blank? && !eth_address.blank?
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

  def self.reward_votings!(username, amount, date)
    self.reward_user!(username, amount, "#{HuntTransaction::VOTING_REWARD_MEMO_PREFIX}#{formatted_date(date)}")
  end

  def self.reward_resteems!(username, amount, date)
    self.reward_user!(username, amount, "#{HuntTransaction::RESTEEM_REWARD_MEMO_PREFIX}#{formatted_date(date)}")
  end

  def self.reward_sponsor!(username, amount, week)
    self.reward_user!(username, amount, "#{HuntTransaction::SPONSOR_REWARD_MEMO_PREFIX}#{week}")
  end

  def self.reward_user!(username, amount, memo)
    return if amount == 0
    raise 'Duplicated Rewards' if self.exists?(receiver: username, memo: memo)

    user = User.find_by(username: username)
    user = User.create!(username: username, encrypted_token: '') unless user

    self.send!(amount, 'steemhunt', user.username, nil, memo)
  end

  def self.send!(amount, sender_name = nil, receiver_name = nil, eth_address = nil, memo = nil)
    return if amount == 0

    sender = sender_name.blank? ? nil : User.find_by(username: sender_name)
    receiver = receiver_name.blank? ? nil : User.find_by(username: receiver_name)

    ActiveRecord::Base.transaction do
      self.create!(
        sender: sender_name,
        receiver: receiver_name,
        eth_address: eth_address,
        amount: amount,
        memo: memo
      )

      unless sender.blank?
        sender.update!(hunt_balance: sender.hunt_balance - amount)
      end
      unless receiver.blank?
        receiver.update!(hunt_balance: receiver.hunt_balance + amount)
      end
    end

    unless eth_address.blank?
      # TODO: ETH Transaction

      # TODO: Rollback DB on errors - should be in a separate transaction
    end
  end
end
