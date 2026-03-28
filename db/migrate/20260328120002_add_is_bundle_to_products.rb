class AddIsBundleToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :is_bundle, :boolean, default: false, null: false
    add_index :products, :is_bundle
  end
end
