class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :product, null: false, foreign_key: true
      t.string :session_id, null: false
      t.integer :value, null: false, default: 1

      t.timestamps
    end

    add_index :votes, [:product_id, :session_id], unique: true
  end
end
