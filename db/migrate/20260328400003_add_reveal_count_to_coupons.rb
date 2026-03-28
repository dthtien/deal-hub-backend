# frozen_string_literal: true

class AddRevealCountToCoupons < ActiveRecord::Migration[8.0]
  def change
    add_column :coupons, :reveal_count, :integer, default: 0, null: false
  end
end
