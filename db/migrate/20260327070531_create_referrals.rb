class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.string :code, null: false
      t.string :session_id
      t.integer :click_count, default: 0, null: false
      t.timestamps
    end
    add_index :referrals, :code, unique: true
    add_index :referrals, :session_id
  end
end
