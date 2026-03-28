# frozen_string_literal: true

class AddClickCountToNotificationLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :notification_logs, :click_count, :integer, default: 0, null: false
  end
end
