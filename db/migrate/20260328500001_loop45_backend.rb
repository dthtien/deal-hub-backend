# frozen_string_literal: true

class Loop45Backend < ActiveRecord::Migration[8.0]
  def change
    # Feature 1: Share breakdown on products
    add_column :products, :share_breakdown, :jsonb, default: {}

    # Feature 3: Store health monitoring on crawl_logs
    add_column :crawl_logs, :health_status, :string, default: 'unknown'

    # Feature 5: Subscription tier
    add_column :subscribers, :tier, :string, default: 'free'
    add_index :subscribers, :tier
  end
end
