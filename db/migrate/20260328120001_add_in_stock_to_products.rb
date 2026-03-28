class AddInStockToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :in_stock, :boolean, default: true, null: false
    add_index :products, :in_stock
  end
end
