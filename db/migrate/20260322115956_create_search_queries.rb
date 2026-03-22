class CreateSearchQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :search_queries do |t|
      t.string :query
      t.integer :count, default: 0

      t.timestamps
    end

    add_index :search_queries, :query, unique: true
  end
end
