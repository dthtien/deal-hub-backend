class AddGoogleOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string
    add_index :users, :google_uid, unique: true
    add_column :users, :provider, :string
    add_column :users, :avatar_url, :string
  end
end
