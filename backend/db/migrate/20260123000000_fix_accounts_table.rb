class FixAccountsTable < ActiveRecord::Migration[8.1]
  def change
    # Drop the old table and recreate it properly
    drop_table :accounts, if_exists: true

    create_table :accounts, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :name, null: false
      t.string :account_type
      t.numeric :balance, default: 0, null: false
      t.uuid :account_group_id

      t.timestamps
    end

    # Add indexes for foreign keys and common queries
    add_index :accounts, :user_id
    add_index :accounts, :account_group_id
    add_index :accounts, [:user_id, :name] # Composite index for user's account lookups
  end
end
