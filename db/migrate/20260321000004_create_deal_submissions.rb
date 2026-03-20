# frozen_string_literal: true

class CreateDealSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :deal_submissions do |t|
      t.string  :title,    null: false
      t.string  :url,      null: false
      t.decimal :price
      t.decimal :old_price
      t.string  :store
      t.text    :description
      t.string  :image_url
      t.string  :submitted_by_email
      t.string  :status,   default: 'pending', null: false  # pending | approved | rejected
      t.timestamps
    end
    add_index :deal_submissions, :status
  end
end
