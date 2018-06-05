class RemoveDefaultFromTransactionTimestamp < ActiveRecord::Migration[5.2]
  def up
    change_column :hunt_transactions, :created_at, :datetime, default: nil, null: false

    HuntTransaction.where('memo LIKE ?', '%week 2%').update_all(created_at: Time.parse('2018-05-28'))
    HuntTransaction.where('memo LIKE ?', '%week 3%').update_all(created_at: Time.parse('2018-06-04'))
  end

  def down
  end
end
