class CreateCategoryAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :category_alerts do |t|
      t.string :email, null: false
      t.string :category, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :category_alerts, [:email, :category], unique: true
    add_index :category_alerts, :category
  end
end
