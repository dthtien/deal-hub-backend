# frozen_string_literal: true

class AddTriggeredPriceToPriceAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :price_alerts, :triggered_price, :decimal, precision: 10, scale: 2
  end
end
