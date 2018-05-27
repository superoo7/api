class AddHuntTokens < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :hunt_balance, :decimal, default: 0.0
    add_column :users, :eth_address, :string, limit: 42, default: nil

    reversible do |dir|
      dir.up do
        change_column :users, :encrypted_token, :string, default: nil, null: true
      end
      dir.down do
        change_column :users, :encrypted_token, :string, null: false
      end
    end

    create_table :hunt_transactions do |t|
      t.references :sender, null: false
      t.references :receiver, default: nil
      t.string :eth_address, default: nil, limit: 42
      t.string :eth_tx_hash, default: nil, limit: 66
      t.decimal :amount, null: false
      t.string :memo, default: nil
    end

    # irreversible by default
    User.find_by(username: 'steemhunt').update(id: 0, hunt_balance: 500000000)

    HuntTransaction.reward_sponsor!('bramd', 506028.772548212, 1)
    HuntTransaction.reward_sponsor!('jsquare', 50602.6246811759, 1)
    HuntTransaction.reward_sponsor!('koyuh8', 25301.81748787850, 1)
    HuntTransaction.reward_sponsor!('armdown', 10119.61567111220, 1)
    HuntTransaction.reward_sponsor!('hwantag', 5060.56555649191, 1)
    HuntTransaction.reward_sponsor!('soosoo', 5060.06040920138, 1)
    HuntTransaction.reward_sponsor!('strelka', 5060.06040920138, 1)
    HuntTransaction.reward_sponsor!('leesongyi', 5060.06040920138, 1)
    HuntTransaction.reward_sponsor!('lcc3108', 5060.06040920138, 1)
    HuntTransaction.reward_sponsor!('hakguan', 5058.54496732980, 1)
    HuntTransaction.reward_sponsor!('carrotcake', 5055.00893629612, 1)
    HuntTransaction.reward_sponsor!('aleister', 2532.80851469858, 1)
  end
end
