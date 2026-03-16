class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets, id: :uuid do |t|
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :budgets, :user_id
  end
end
