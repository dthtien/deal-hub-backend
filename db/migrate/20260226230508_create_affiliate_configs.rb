class CreateAffiliateConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :affiliate_configs do |t|
      t.string :store, null: false
      t.string :param_name, null: false
      t.string :param_value, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :affiliate_configs, :store, unique: true
  end
end
