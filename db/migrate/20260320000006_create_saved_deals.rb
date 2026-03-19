class CreateSavedDeals < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_deals do |t|
      t.bigint :user_id, null: false
      t.bigint :product_id, null: false
      t.timestamps
    end

    add_index :saved_deals, [:user_id, :product_id], unique: true
    add_index :saved_deals, :user_id
  end
end
