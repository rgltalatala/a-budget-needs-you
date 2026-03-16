class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :category_id, null: false
      t.date :date, null: false
      t.text :payee
      t.numeric :amount, null: false
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :transactions, :account_id
    add_index :transactions, :category_id
    add_index :transactions, :user_id
    add_index :transactions, :date
    add_index :transactions, [:user_id, :date]
  end
end
