class AddAffiliateToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :affiliate_network, :string
    add_column :products, :commission_rate, :decimal, precision: 5, scale: 2
  end
end
