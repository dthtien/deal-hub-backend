class FixUsersEmailIndex < ActiveRecord::Migration[8.0]
  def up
    # Remove existing email index if present (may exist from create_users or add_auth_to_users)
    remove_index :users, :email if index_exists?(:users, :email)
    remove_index :users, :username if index_exists?(:users, :username)

    # Re-add cleanly with unique constraint
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :username, unique: true unless index_exists?(:users, :username)
  end

  def down
    remove_index :users, :email if index_exists?(:users, :email)
    remove_index :users, :username if index_exists?(:users, :username)
  end
end
