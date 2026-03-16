class CreateBudgetMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_months, id: :uuid do |t|
      t.uuid :budget_id, null: false
      t.date :month, null: false
      t.numeric :available, default: 0
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :budget_months, :budget_id
    add_index :budget_months, :user_id
    add_index :budget_months, :month
    add_index :budget_months, [:budget_id, :month], unique: true
  end
end
