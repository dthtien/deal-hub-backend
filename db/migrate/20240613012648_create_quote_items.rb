class CreateQuoteItems < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_items do |t|
      t.string :provider
      t.decimal :annual_price
      t.decimal :monthly_price
      t.text :description
      t.string :cover_type
      t.string :quote_id, index: true
      t.jsonb :response_details

      t.timestamps
    end

    add_index :quote_items, %i[quote_id provider cover_type], unique: true
  end
end
