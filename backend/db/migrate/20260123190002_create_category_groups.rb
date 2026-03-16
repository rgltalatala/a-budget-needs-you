class CreateCategoryGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :category_groups, id: :uuid do |t|
      t.uuid :budget_month_id
      t.string :name, null: false
      t.boolean :is_default, default: false
      t.uuid :user_id

      t.timestamps
    end

    add_index :category_groups, :budget_month_id
    add_index :category_groups, :user_id
    add_index :category_groups, [:budget_month_id, :name]
  end
end
