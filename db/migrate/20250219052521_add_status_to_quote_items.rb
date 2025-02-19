class AddStatusToQuoteItems < ActiveRecord::Migration[7.1]
  def change
    add_column :quote_items, :status, :integer, default: 0
  end
end
