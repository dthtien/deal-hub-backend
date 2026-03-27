class AddResultCountToSearchQueries < ActiveRecord::Migration[8.0]
  def change
    add_column :search_queries, :result_count_total, :integer, default: 0
    add_column :search_queries, :search_count, :integer, default: 0
  end
end
