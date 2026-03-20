class CreateAiDealAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_deal_analyses do |t|
      t.bigint :product_id, null: false
      t.string :recommendation, null: false  # BUY_NOW | WAIT | GOOD_DEAL | OVERPRICED
      t.string :confidence                   # HIGH | MEDIUM | LOW
      t.text :reasoning
      t.decimal :lowest_90d
      t.decimal :avg_90d
      t.decimal :highest_90d
      t.integer :price_drop_count
      t.boolean :is_lowest_ever, default: false
      t.datetime :analysed_at, null: false
      t.timestamps
    end

    add_index :ai_deal_analyses, :product_id, unique: true
  end
end
