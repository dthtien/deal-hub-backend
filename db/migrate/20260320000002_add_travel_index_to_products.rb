class AddTravelIndexToProducts < ActiveRecord::Migration[8.0]
  def change
    add_index :products, "(categories @> ARRAY['travel']::varchar[])",
              name: 'index_products_on_travel_category',
              using: :gin
  end
end
