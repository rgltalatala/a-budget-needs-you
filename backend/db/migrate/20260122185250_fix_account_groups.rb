class FixAccountGroups < ActiveRecord::Migration[8.1]
  def change
    rename_column :account_groups, :user, :user_id
    change_column_null :account_groups, :user_id, false
    change_column_null :account_groups, :name, false
    change_column_default :account_groups, :sort_order, 0

    add_index :account_groups, :user_id
  end
end
