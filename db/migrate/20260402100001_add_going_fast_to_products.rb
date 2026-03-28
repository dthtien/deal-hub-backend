# frozen_string_literal: true

class AddGoingFastToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :going_fast, :boolean, default: false, null: false
  end
end
