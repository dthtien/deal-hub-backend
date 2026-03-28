# frozen_string_literal: true

class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      t.string :session_id, null: false
      t.jsonb :preferences, default: {}
      t.datetime :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
    add_index :user_preferences, :session_id, unique: true
  end
end
