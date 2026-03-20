# frozen_string_literal: true

class AddExpiredAndFeaturedToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :expired, :boolean, default: false, null: false unless column_exists?(:products, :expired)
    add_column :products, :featured, :boolean, default: false, null: false unless column_exists?(:products, :featured)
    add_index :products, :expired unless index_exists?(:products, :expired)
    add_index :products, :featured unless index_exists?(:products, :featured)
  end
end
