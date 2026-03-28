# frozen_string_literal: true

class CreateComparisonSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :comparison_sessions do |t|
      t.string :session_id, null: false
      t.integer :product_ids, array: true, default: []
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :comparison_sessions, :session_id
    add_index :comparison_sessions, :created_at
  end
end
