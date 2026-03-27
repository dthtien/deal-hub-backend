class AddCascadeDeleteToProductAssociations < ActiveRecord::Migration[8.0]
  def change
    # Drop and re-add FKs with ON DELETE CASCADE so Postgres auto-cleans
    # child records when products are deleted via delete_all

    tables = %i[
      votes comments price_histories price_alerts
      click_trackings deal_ratings collection_items
      ai_deal_analyses deal_reports store_follows
    ]

    tables.each do |table|
      next unless table_exists?(table)

      fk = foreign_keys(table).find { |f| f.to_table == 'products' }
      next unless fk

      remove_foreign_key table, :products
      add_foreign_key table, :products, on_delete: :cascade
    end
  end
end
