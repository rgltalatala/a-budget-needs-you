class CreateAccountGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :account_groups, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :name, null: false
      t.integer :sort_order, default: 0, null: false

      t.timestamps
    end

    add_index :account_groups, :user_id
  end
end
