# frozen_string_literal: true

class AddCompoundIndexesToProducts < ActiveRecord::Migration[8.0]
  def change
    # Compound index for sorting active deals by score (common pattern in index/top_picks)
    unless index_exists?(:products, [:expired, :deal_score])
      add_index :products, [:expired, :deal_score], name: 'index_products_on_expired_and_deal_score'
    end

    # Compound index for going_fast + expired filter
    unless index_exists?(:products, [:going_fast, :expired])
      add_index :products, [:going_fast, :expired], name: 'index_products_on_going_fast_and_expired'
    end
  end
end
