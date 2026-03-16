class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.uuid :user
      t.string :name
      t.string :account_type
      t.decimal :balance
      t.uuid :account_group

      t.timestamps
    end
  end
end
