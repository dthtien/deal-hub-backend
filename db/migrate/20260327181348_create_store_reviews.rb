class CreateStoreReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :store_reviews do |t|
      t.string :store_name, null: false
      t.integer :rating, null: false
      t.text :comment
      t.string :session_id

      t.timestamps
    end
    add_index :store_reviews, :store_name
    add_index :store_reviews, :session_id
  end
end
