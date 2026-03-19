# frozen_string_literal: true

class CreatePriceAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :price_alerts do |t|
      t.string :email, null: false
      t.bigint :product_id, null: false
      t.decimal :target_price, null: false
      t.boolean :triggered, default: false
      t.datetime :triggered_at
      t.timestamps
    end

    add_index :price_alerts, [:product_id, :triggered]
    add_index :price_alerts, :email
  end
end
