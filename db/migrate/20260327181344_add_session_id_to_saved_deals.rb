class AddSessionIdToSavedDeals < ActiveRecord::Migration[8.0]
  def change
    add_column :saved_deals, :session_id, :string
    # Allow user_id to be null for session-based saves
    change_column_null :saved_deals, :user_id, true
    add_index :saved_deals, [:session_id, :product_id], unique: true, name: 'index_saved_deals_on_session_id_and_product_id'
    add_index :saved_deals, :session_id
  end
end
