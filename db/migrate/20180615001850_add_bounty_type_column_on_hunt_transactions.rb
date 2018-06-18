class AddBountyTypeColumnOnHuntTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :hunt_transactions, :bounty_type, :string, default: nil
    add_index :hunt_transactions, :bounty_type

    # HuntTransaction.where('memo LIKE ?', "#{HuntTransaction::SPONSOR_REWARD_MEMO_PREFIX}%").update_all(bounty_type: 'sponsor')
    # HuntTransaction.where('memo LIKE ?', "#{HuntTransaction::VOTING_REWARD_MEMO_PREFIX}%").update_all(bounty_type: 'voting')
    # HuntTransaction.where('memo LIKE ?', "#{HuntTransaction::RESTEEM_REWARD_MEMO_PREFIX}%").update_all(bounty_type: 'resteem')
  end
end
