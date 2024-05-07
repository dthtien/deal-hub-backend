class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name, index: true
      t.float :price
      t.string :store_product_id, index: true
      t.string :brand
      t.string :available_states, array: true, default: []
      t.string :image_url
      t.string :store_path
      t.string :store, index: true
      t.text :description
      t.string :categories, array: true, default: []

      t.timestamps
    end

    add_index :products, %i[store_product_id store], unique: true
    add_index :products, :categories, using: 'gin'
  end
end
