class CreateDealOfDayHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :deal_of_day_histories do |t|
      t.bigint :product_id, null: false
      t.date :date, null: false
      t.timestamps
    end

    add_index :deal_of_day_histories, :date, unique: true
    add_index :deal_of_day_histories, :product_id
  end
end
