class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :store, null: false
      t.string :code, null: false
      t.string :description
      t.decimal :discount_value, precision: 8, scale: 2
      t.string :discount_type, default: 'percent' # percent | fixed
      t.datetime :expires_at
      t.boolean :verified, default: false
      t.boolean :active, default: true
      t.integer :use_count, default: 0
      t.string :minimum_spend

      t.timestamps
    end

    add_index :coupons, :store
    add_index :coupons, :active
    add_index :coupons, :code
  end
end
