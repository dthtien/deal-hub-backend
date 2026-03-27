class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.string :url, null: false
      t.string :secret, null: false
      t.boolean :active, default: true, null: false
      t.string :events, array: true, default: []
      t.timestamps
    end
    add_index :webhooks, :active
  end
end
