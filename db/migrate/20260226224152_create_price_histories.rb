class CreatePriceHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :price_histories do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :price, null: false, precision: 10, scale: 2
      t.date :recorded_on, null: false

      t.timestamps
    end

    add_index :price_histories, [:product_id, :recorded_on], unique: true
  end
end
