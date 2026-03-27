class AddTagsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :tags, :string, array: true, default: []
  end
end
