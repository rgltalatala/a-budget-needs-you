class CreateSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :summaries, id: :uuid do |t|
      t.uuid :budget_month_id, null: false
      t.numeric :income, default: 0
      t.numeric :carryover, default: 0
      t.numeric :available, default: 0
      t.text :notes
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :summaries, :budget_month_id, unique: true
    add_index :summaries, :user_id
  end
end
