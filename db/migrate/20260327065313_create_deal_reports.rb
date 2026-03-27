class CreateDealReports < ActiveRecord::Migration[8.0]
  def change
    create_table :deal_reports do |t|
      t.bigint :product_id, null: false
      t.string :reason, null: false
      t.string :session_id
      t.datetime :created_at, null: false
    end
    add_index :deal_reports, :product_id
    add_index :deal_reports, :reason
  end
end
