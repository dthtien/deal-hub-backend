# frozen_string_literal: true

class CreateDealScoreHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :deal_score_histories do |t|
      t.bigint :product_id, null: false
      t.decimal :score, precision: 8, scale: 2
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :deal_score_histories, :product_id
    add_index :deal_score_histories, [:product_id, :recorded_at]
  end
end
