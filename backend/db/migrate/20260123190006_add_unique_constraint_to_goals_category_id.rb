class AddUniqueConstraintToGoalsCategoryId < ActiveRecord::Migration[8.1]
  def change
    remove_index :goals, :category_id
    add_index :goals, :category_id, unique: true
  end
end
