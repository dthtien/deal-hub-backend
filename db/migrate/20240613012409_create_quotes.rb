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
      t.boolean :financed, default: false
      t.string :primary_usage
      t.string :days_wfh
      t.boolean :peak_hour_driving, default: false
      t.string :cover_type
      t.date :driver_dob
      t.string :driver_gender
      t.string :driver_first_name
      t.string :driver_last_name
      t.string :driver_email
      t.string :driver_phone_number
      t.string :driver_employment_status
      t.string :driver_licence_age
      t.string :driver_option
      t.boolean :modified, default: false
      t.boolean :has_claim_occurrences, default: false
      t.boolean :has_other_accessories, default: false
      t.jsonb :claim_occurrences, default: []
      t.jsonb :additional_drivers, default: []
      t.boolean :has_younger_driver, default: false
      t.jsonb :parking, default: {}
      t.integer :km_per_year

      t.timestamps
    end
  end
end
