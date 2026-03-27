class CreateStoreFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :store_follows do |t|
      t.string :session_id, null: false
      t.string :store_name, null: false
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :store_follows, [:session_id, :store_name], unique: true
  end
end
