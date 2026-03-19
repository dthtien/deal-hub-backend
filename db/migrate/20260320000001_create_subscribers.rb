class CreateSubscribers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :status, default: 'active'
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :subscribers, :email, unique: true
    add_index :subscribers, :status
  end
end
