class AddAbVariantToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :ab_variant, :string, default: 'A'
  end
end
