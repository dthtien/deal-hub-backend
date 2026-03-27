class AddFlashDealToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :flash_deal, :boolean, default: false
    add_column :products, :flash_expires_at, :datetime
    add_index :products, [:flash_deal, :flash_expires_at]
  end
end
