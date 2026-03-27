class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :cover_image_url
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :collections, :slug, unique: true
  end
end
