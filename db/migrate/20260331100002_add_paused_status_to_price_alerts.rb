# frozen_string_literal: true

class AddPausedStatusToPriceAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :price_alerts, :status, :string, default: 'active'
    add_index :price_alerts, :status
  end
end
