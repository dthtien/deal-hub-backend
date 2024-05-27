class AddIndexToTextFieldsToProducts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    enable_extension :pg_trgm

    unless index_exists?(:products, :name, name: :products_name_gin_index)
      add_index :products, :name, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, name: :products_name_gin_index
    end
    unless index_exists?(:products, :description, name: :products_description_gin_index)
      add_index :products, :description, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, name: :products_description_gin_index
    end

    return if index_exists?(:products, :brand, name: :products_brand_gin_index)

    add_index :products, :brand, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, name: :products_brand_gin_index
  end

  def down
    if index_exists?(:products, :name, name: :products_name_gin_index)
      remove_index :products, name: :products_name_gin_index
    end

    if index_exists?(:products, :description, name: :products_description_gin_index)
      remove_index :products, name: :products_description_gin_index
    end

    return unless index_exists?(:products, :brand, name: :products_brand_gin_index)

    remove_index :products, name: :products_brand_gin_index
  end
end
