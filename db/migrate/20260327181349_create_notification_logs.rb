class CreateNotificationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_logs do |t|
      t.string :notification_type, null: false
      t.string :recipient, null: false
      t.string :subject
      t.string :status, null: false, default: 'sent'

      t.timestamps
    end
    add_index :notification_logs, :recipient
    add_index :notification_logs, :status
    add_index :notification_logs, :created_at
  end
end
