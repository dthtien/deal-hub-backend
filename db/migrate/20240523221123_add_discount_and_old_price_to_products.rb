class AddDiscountAndOldPriceToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :discount, :decimal
    add_column :products, :old_price, :decimal
  end
end
