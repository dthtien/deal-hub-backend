# frozen_string_literal: true

class CreatePriceHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :price_histories do |t|
      t.bigint :product_id, null: false
      t.decimal :price, null: false
      t.decimal :old_price
      t.decimal :discount
      t.datetime :recorded_at, null: false
      t.timestamps
    end

    add_index :price_histories, [:product_id, :recorded_at]
  end
end
