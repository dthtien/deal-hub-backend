class CreateCrawlLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :crawl_logs do |t|
      t.string :store
      t.integer :products_found
      t.integer :products_updated
      t.integer :products_new
      t.float :duration_seconds
      t.datetime :crawled_at

      t.timestamps
    end
  end
end
