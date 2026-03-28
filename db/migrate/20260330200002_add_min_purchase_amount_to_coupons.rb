class AddMinPurchaseAmountToCoupons < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:coupons, :min_purchase_amount)
      add_column :coupons, :min_purchase_amount, :decimal, precision: 10, scale: 2
    end
  end
end
