class AddDealScoreToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :deal_score, :integer unless column_exists?(:products, :deal_score)
    add_index :products, :deal_score unless index_exists?(:products, :deal_score)
  end
end
