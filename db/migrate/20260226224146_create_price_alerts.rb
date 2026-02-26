class CreatePriceAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :price_alerts do |t|
      t.references :product, null: false, foreign_key: true
      t.string :email, null: false
      t.decimal :target_price, null: false, precision: 10, scale: 2
      t.integer :status, default: 0, null: false  # 0=active, 1=triggered, 2=cancelled
      t.datetime :triggered_at

      t.timestamps
    end

    add_index :price_alerts, [:email, :product_id], unique: true
    add_index :price_alerts, :status
  end
end
