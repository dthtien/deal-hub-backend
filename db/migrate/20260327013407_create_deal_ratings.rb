class CreateDealRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :deal_ratings do |t|
      t.references :product, null: false, foreign_key: true
      t.string :session_id, null: false
      t.integer :rating, null: false

      t.timestamps
    end
    add_index :deal_ratings, [:product_id, :session_id], unique: true
  end
end
