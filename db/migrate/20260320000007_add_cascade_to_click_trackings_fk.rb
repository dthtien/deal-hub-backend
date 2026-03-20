class AddCascadeToClickTrackingsFk < ActiveRecord::Migration[8.0]
  def up
    # Remove old FK without cascade
    remove_foreign_key :click_trackings, :products

    # Re-add with ON DELETE CASCADE
    add_foreign_key :click_trackings, :products, on_delete: :cascade
  end

  def down
    remove_foreign_key :click_trackings, :products
    add_foreign_key :click_trackings, :products
  end
end
