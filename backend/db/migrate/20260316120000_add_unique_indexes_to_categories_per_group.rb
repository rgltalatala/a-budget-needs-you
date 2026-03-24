# Enforces: no duplicate category *names* for the same user within the same category group.
# Rows with user_id NULL are excluded from uniqueness (legacy / edge cases).
class AddUniqueIndexesToCategoriesPerGroup < ActiveRecord::Migration[8.1]
  def up
    remove_index :categories, name: "index_categories_on_user_id_and_name"

    add_index :categories,
              [:user_id, :category_group_id, :name],
              unique: true,
              name: "index_categories_on_user_group_name_unique",
              where: "category_group_id IS NOT NULL AND user_id IS NOT NULL"

    add_index :categories,
              [:user_id, :name],
              unique: true,
              name: "index_categories_on_user_and_name_no_group_unique",
              where: "category_group_id IS NULL AND user_id IS NOT NULL"

    # Non-unique lookup for unscoped queries (optional but keeps parity with old index intent)
    add_index :categories, [:user_id, :name], name: "index_categories_on_user_id_and_name"
  end

  def down
    remove_index :categories, name: "index_categories_on_user_group_name_unique"
    remove_index :categories, name: "index_categories_on_user_and_name_no_group_unique"
    remove_index :categories, name: "index_categories_on_user_id_and_name"

    add_index :categories, [:user_id, :name], name: "index_categories_on_user_id_and_name"
  end
end
