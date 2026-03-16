class AddPasswordDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_digest, :string
    
    # Set a temporary password for existing users (they'll need to reset)
    User.reset_column_information
    User.find_each do |user|
      user.update_column(:password_digest, BCrypt::Password.create("temp_password_#{user.id}"))
    end
    
    change_column_null :users, :password_digest, false
  end
end
