class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals, id: :uuid do |t|
      t.uuid :category_id, null: false
      t.string :goal_type, null: false
      t.numeric :target_amount
      t.date :target_date
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :goals, :category_id
    add_index :goals, :user_id
  end
end
