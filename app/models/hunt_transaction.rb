require 'utils'

class HuntTransaction < ApplicationRecord
  BOUNTY_TYPES = %w(sponsor voting resteem sp_claim posting commenting referral report moderator)
  SPONSOR_REWARD_MEMO_PREFIX = 'Weekly reward for delegation sponsor - week ' # + num
  VOTING_REWARD_MEMO_PREFIX = 'Daily reward for voting contribution - ' # + formatted date (%e %b %Y)
  RESTEEM_REWARD_MEMO_PREFIX = 'Daily reward for resteem contribution - ' # + formatted date (%e %b %Y)
  REPORT_REWARD_MEMO_PREFIX = 'Bounty rewards for reporting abusing users -' # + formatted date (%e %b %Y)

  validates_presence_of :amount, :memo
  validate :validate_sender_and_receiver, :validate_eth_format
  validates :memo, length: { maximum: 255 }
  validates :bounty_type, inclusion: { in: BOUNTY_TYPES }


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

  def self.reward_reporter!(username, amount)
    if user = User.find_by(username: username)
      today = Time.zone.today.to_time
      reward_user!(username, amount, 'report', "#{HuntTransaction::REPORT_REWARD_MEMO_PREFIX}#{formatted_date(today)}", false)
      puts "Reporter HUNT balance: #{user.hunt_balance} -> #{user.reload.hunt_balance}"
    else
      puts "No user found"
    end
  end

  def self.reward_sponsor!(username, amount, week)
    reward_user!(username, amount, 'sponsor', "#{HuntTransaction::SPONSOR_REWARD_MEMO_PREFIX}#{week}", true)
  end

  def self.reward_votings!(username, amount, date)
    reward_user!(username, amount, 'voting', "#{HuntTransaction::VOTING_REWARD_MEMO_PREFIX}#{formatted_date(date)}", true)
  end

  def self.reward_resteems!(username, amount, date)
    reward_user!(username, amount, 'resteem', "#{HuntTransaction::RESTEEM_REWARD_MEMO_PREFIX}#{formatted_date(date)}", true)
  end

  private_class_method def self.reward_user!(username, amount, bounty_type, memo, check_dups = false)
    return if amount == 0
    raise 'Duplicated Rewards' if check_dups && self.exists?(receiver: username, memo: memo)

    user = User.find_by(username: username)
    user = User.create!(username: username, encrypted_token: '') unless user

    send!(amount, 'steemhunt', user.username, nil, bounty_type, memo)
  end

  private_class_method def self.send!(amount, sender_name = nil, receiver_name = nil, eth_address = nil, bounty_type = nil, memo = nil)
    return if amount == 0

    sender = sender_name.blank? ? nil : User.find_by(username: sender_name)
    receiver = receiver_name.blank? ? nil : User.find_by(username: receiver_name)

    ActiveRecord::Base.transaction do
      self.create!(
        sender: sender_name,
        receiver: receiver_name,
        eth_address: eth_address,
        amount: amount,
        bounty_type: bounty_type,
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
