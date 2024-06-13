class CreateQuoteItems < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_items do |t|
      t.string :provider
      t.decimal :annual_price
      t.decimal :monthly_price
      t.string :quote_id
      t.jsonb :response_details

      t.timestamps
    end
  end
end
