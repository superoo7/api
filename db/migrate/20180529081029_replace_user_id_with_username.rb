class ReplaceUserIdWithUsername < ActiveRecord::Migration[5.2]
  def up
    add_column :hunt_transactions, :sender, :string, index: true
    add_column :hunt_transactions, :receiver, :string, index: true

    HuntTransaction.all.each do |t|
      t.update!(
        sender: User.find_by(id: t.sender_id).try(:username),
        receiver: User.find_by(id: t.receiver_id).try(:username)
      )
    end

    remove_column :hunt_transactions, :sender_id
    remove_column :hunt_transactions, :receiver_id

    add_index :hunt_transactions, :sender
    add_index :hunt_transactions, :receiver
  end

  def down
    add_column :hunt_transactions, :sender_id, :integer, index: true
    add_column :hunt_transactions, :receiver_id, :integer, index: true

    HuntTransaction.all.each do |t|
      t.update!(
        sender_id: User.find_by(username: t.sender).try(:id),
        receiver_id: User.find_by(username: t.receiver).try(:id)
      )
    end

    remove_column :hunt_transactions, :sender
    remove_column :hunt_transactions, :receiver

    add_index :hunt_transactions, :sender_id
    add_index :hunt_transactions, :receiver_id
  end
end
