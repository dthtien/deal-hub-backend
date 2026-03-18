class CreateClickTrackings < ActiveRecord::Migration[7.1]
  def change
    create_table :click_trackings do |t|
      t.bigint :product_id, null: false
      t.string :store
      t.string :ip_address
      t.text :user_agent
      t.string :referrer
      t.datetime :clicked_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :click_trackings, :product_id
    add_index :click_trackings, :clicked_at
    add_index :click_trackings, :store
    add_foreign_key :click_trackings, :products
  end
end
