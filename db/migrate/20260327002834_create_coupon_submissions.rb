class CreateCouponSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :coupon_submissions do |t|
      t.string :store, null: false
      t.string :code, null: false
      t.string :description
      t.decimal :discount_value, precision: 8, scale: 2
      t.string :discount_type, default: 'percent'
      t.string :submitted_by_email
      t.string :status, default: 'pending', null: false

      t.timestamps
    end
    add_index :coupon_submissions, :status
  end
end
