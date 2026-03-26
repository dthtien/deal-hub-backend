class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :product, null: false, foreign_key: true
      t.string :session_id
      t.string :name
      t.text :body, null: false

      t.datetime :created_at, null: false
    end
  end
end
