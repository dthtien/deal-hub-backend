# frozen_string_literal: true

class CreateRevenueEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :revenue_events do |t|
      t.bigint :product_id
      t.string :click_id
      t.decimal :estimated_value, precision: 10, scale: 4, default: 0.0
      t.string :store
      t.timestamp :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
    add_index :revenue_events, :product_id
    add_index :revenue_events, :store
    add_index :revenue_events, :created_at
  end
end
