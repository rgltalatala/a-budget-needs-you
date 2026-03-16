class CreateCategoryMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :category_months, id: :uuid do |t|
      t.uuid :category_id, null: false
      t.uuid :category_group_id
      t.numeric :spent, default: 0
      t.numeric :allotted, default: 0
      t.numeric :balance, default: 0
      t.date :month
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :category_months, :category_id
    add_index :category_months, :category_group_id
    add_index :category_months, :user_id
    add_index :category_months, :month
    add_index :category_months, [:category_id, :month]
  end
end
