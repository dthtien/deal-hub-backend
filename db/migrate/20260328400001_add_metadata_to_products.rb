# frozen_string_literal: true

class AddMetadataToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :metadata, :jsonb, default: {}
    add_index :products, :metadata, using: :gin
  end
end
