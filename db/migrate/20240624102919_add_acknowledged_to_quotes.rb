class AddAcknowledgedToQuotes < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :acknowledged, :boolean
  end
end
