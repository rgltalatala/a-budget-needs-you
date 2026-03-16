# Allow account_group_id to store string ids (e.g. "7") when account_groups use integer ids.
# Keeps compatibility with UUID; no foreign key in schema so this is a type change only.
class AllowStringAccountGroupId < ActiveRecord::Migration[8.1]
  def up
    change_column :accounts, :account_group_id, :string, limit: 36
  end

  def down
    change_column :accounts, :account_group_id, :uuid
  end
end
