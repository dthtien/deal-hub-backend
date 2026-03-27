class CreateCollectionItems < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_items do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
