# frozen_string_literal: true

class Loop47Backend < ActiveRecord::Migration[8.0]
  def change
    # Feature 1: Referral conversion tracking
    add_column :referrals, :converted_at, :datetime
    add_column :referrals, :conversion_count, :integer, default: 0, null: false

    # Feature 2: Deal spotlights (editorial)
    create_table :deal_spotlights do |t|
      t.references :product, null: false, foreign_key: true
      t.string  :title,         null: false
      t.text    :description
      t.datetime :featured_until
      t.integer :position,      default: 0, null: false
      t.boolean :active,        default: true, null: false
      t.timestamps
    end

    add_index :deal_spotlights, [:active, :position]

    # Feature 5: Smart deal expiry reason
    add_column :products, :expiry_reason, :string
  end
end
