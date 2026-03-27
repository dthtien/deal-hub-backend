class AddKeywordToPriceAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :price_alerts, :keyword, :string
  end
end
