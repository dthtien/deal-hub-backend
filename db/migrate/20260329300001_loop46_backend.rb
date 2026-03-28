class Loop46Backend < ActiveRecord::Migration[8.0]
  def change
    # Feature 1: Funnel tracking on click_trackings
    add_column :click_trackings, :funnel_stage, :string
    add_column :click_trackings, :session_id, :string
    add_index :click_trackings, :funnel_stage
    add_index :click_trackings, :session_id

    # Feature 2: Deal authenticity verification on products
    add_column :products, :price_verified, :boolean
    add_column :products, :verified_at, :datetime
  end
end
