class MakePriceAlertProductIdNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :price_alerts, :product_id, true
    change_column_null :price_alerts, :target_price, true
  end
end
