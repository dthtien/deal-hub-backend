# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # products.discount - used in sorting by discount
    unless index_exists?(:products, :discount)
      add_index :products, :discount
    end

    # products.created_at - used in new_today queries and ordering
    unless index_exists?(:products, :created_at)
      add_index :products, :created_at
    end

    # Composite index for common query pattern: active deals ordered by discount
    unless index_exists?(:products, [:expired, :discount])
      add_index :products, [:expired, :discount]
    end

    # Composite index for store + expired (common filter combination)
    unless index_exists?(:products, [:store, :expired])
      add_index :products, [:store, :expired]
    end
  end
end
