class AddStatusToComments < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:comments, :status)
      add_column :comments, :status, :string, default: 'active', null: false
    end
    add_index :comments, :status, if_not_exists: true
  end
end
