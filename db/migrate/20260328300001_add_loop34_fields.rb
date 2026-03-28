class AddLoop34Fields < ActiveRecord::Migration[8.0]
  def change
    # Email open tracking
    add_column :notification_logs, :opened_at, :datetime, null: true
    add_index :notification_logs, :opened_at

    # Bundle detection v2
    add_column :products, :bundle_quantity, :integer, default: 1, null: false
    add_column :products, :price_per_unit, :decimal, precision: 10, scale: 2, null: true

    # Crawl schedule optimization - yield_rate
    add_column :crawl_logs, :yield_rate, :float, null: true
  end
end
