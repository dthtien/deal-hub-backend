class AddSpecificationsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :specifications, :jsonb, default: {}
    add_index :products, :specifications, using: :gin
  end
end
