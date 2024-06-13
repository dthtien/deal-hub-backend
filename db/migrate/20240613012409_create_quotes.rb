class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.integer :user_id, index: true
      t.string :status
      t.date :policy_start_date
      t.string :current_insurer
      t.string :state
      t.string :suburb
      t.string :postcode
      t.string :address_line1
      t.string :plate
      t.boolean :financed
      t.string :primary_usage
      t.string :days_wfh
      t.boolean :peak_hour_driving
      t.string :cover_type
      t.date :driver_dob
      t.string :driver_gender
      t.boolean :has_claim_occurrences
      t.jsonb :claim_occurrences, default: []
      t.jsonb :additional_drivers, default: []
      t.jsonb :parking, default: {}
      t.integer :km_per_year

      t.timestamps
    end
  end
end
