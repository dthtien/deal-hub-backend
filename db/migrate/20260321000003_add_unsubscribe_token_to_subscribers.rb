# frozen_string_literal: true

class AddUnsubscribeTokenToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :unsubscribe_token, :string unless column_exists?(:subscribers, :unsubscribe_token)
    add_column :subscribers, :preferences, :jsonb, default: {} unless column_exists?(:subscribers, :preferences)
    add_index :subscribers, :unsubscribe_token, unique: true unless index_exists?(:subscribers, :unsubscribe_token)

    # Backfill tokens for existing subscribers
    reversible do |dir|
      dir.up { execute "UPDATE subscribers SET unsubscribe_token = gen_random_uuid()::text WHERE unsubscribe_token IS NULL" }
    end
  end
end
