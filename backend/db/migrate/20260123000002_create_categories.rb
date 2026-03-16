class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.uuid :category_group_id
      t.string :name, null: false
      t.boolean :is_default, default: false
      t.uuid :user_id

      t.timestamps
    end

    add_index :categories, :user_id
    add_index :categories, :category_group_id
    add_index :categories, [:user_id, :name]
  end
end
