class AddAuthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)
    add_column :users, :username, :string unless column_exists?(:users, :username)
    # Indexes handled safely in 20260320000008_fix_users_email_index
  end
end
