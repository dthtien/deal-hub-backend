# frozen_string_literal: true

class CreateWebhookDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_deliveries do |t|
      t.bigint :webhook_id, null: false
      t.jsonb :payload
      t.integer :response_status
      t.datetime :delivered_at
      t.boolean :failed, default: false, null: false
      t.timestamps
    end
    add_index :webhook_deliveries, :webhook_id
    add_index :webhook_deliveries, :failed
  end
end
