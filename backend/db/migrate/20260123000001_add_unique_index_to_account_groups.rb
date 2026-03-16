# db/migrate/XXXXXXXXXXXX_add_unique_index_to_account_groups.rb
class AddUniqueIndexToAccountGroups < ActiveRecord::Migration[8.1]
  def change
    # Adds a unique index to enforce uniqueness at the DB level
    add_index :account_groups, [:user_id, :name], unique: true, name: 'index_account_groups_on_user_id_and_name'
  end
end
