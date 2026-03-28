# frozen_string_literal: true

class AddStatusToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :status, :string, default: 'active'
    add_index :products, :status
  end
end
