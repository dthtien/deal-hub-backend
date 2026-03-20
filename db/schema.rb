# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_03_20_000008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.string "status", default: "active"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_subscribers_on_email", unique: true
    t.index ["status"], name: "index_subscribers_on_status"
  end

  create_table "price_histories", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.decimal "price", null: false
    t.decimal "old_price"
    t.decimal "discount"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "recorded_at"], name: "index_price_histories_on_product_id_and_recorded_at"
  end

  create_table "price_alerts", force: :cascade do |t|
    t.string "email", null: false
    t.bigint "product_id", null: false
    t.decimal "target_price", null: false
    t.boolean "triggered", default: false
    t.datetime "triggered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "triggered"], name: "index_price_alerts_on_product_id_and_triggered"
    t.index ["email"], name: "index_price_alerts_on_email"
  end

  create_table "click_trackings", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "store"
    t.string "ip_address"
    t.text "user_agent"
    t.string "referrer"
    t.datetime "clicked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clicked_at"], name: "index_click_trackings_on_clicked_at"
    t.index ["product_id"], name: "index_click_trackings_on_product_id"
    t.index ["store"], name: "index_click_trackings_on_store"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.float "price"
    t.string "store_product_id"
    t.string "brand"
    t.string "available_states", default: [], array: true
    t.string "image_url"
    t.string "store_path"
    t.string "store"
    t.text "description"
    t.string "categories", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "discount"
    t.decimal "old_price"
    t.index ["brand"], name: "products_brand_gin_index", opclass: :gin_trgm_ops, using: :gin
    t.index ["categories"], name: "index_products_on_categories", using: :gin
    t.index ["description"], name: "products_description_gin_index", opclass: :gin_trgm_ops, using: :gin
    t.index ["name"], name: "index_products_on_name"
    t.index ["name"], name: "products_name_gin_index", opclass: :gin_trgm_ops, using: :gin
    t.index ["store"], name: "index_products_on_store"
    t.index ["store_product_id", "store"], name: "index_products_on_store_product_id_and_store", unique: true
    t.index ["store_product_id"], name: "index_products_on_store_product_id"

  end

  create_table "quote_items", force: :cascade do |t|
    t.string "provider"
    t.decimal "annual_price"
    t.decimal "monthly_price"
    t.text "description"
    t.string "cover_type"
    t.uuid "quote_id"
    t.jsonb "response_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.index ["quote_id", "provider", "cover_type"], name: "index_quote_items_on_quote_id_and_provider_and_cover_type", unique: true
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
  end

  create_table "quotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "user_id"
    t.string "status"
    t.date "policy_start_date"
    t.string "current_insurer"
    t.string "state"
    t.string "suburb"
    t.string "postcode"
    t.string "address_line1"
    t.string "plate"
    t.boolean "financed", default: false
    t.string "primary_usage"
    t.string "days_wfh"
    t.boolean "peak_hour_driving", default: false
    t.string "cover_type"
    t.date "driver_dob"
    t.string "driver_gender"
    t.string "driver_first_name"
    t.string "driver_last_name"
    t.string "driver_email"
    t.string "driver_phone_number"
    t.string "driver_employment_status"
    t.string "driver_licence_age"
    t.string "driver_option"
    t.boolean "modified", default: false
    t.boolean "has_claim_occurrences", default: false
    t.boolean "has_other_accessories", default: false
    t.jsonb "claim_occurrences", default: []
    t.jsonb "additional_drivers", default: []
    t.boolean "has_younger_driver", default: false
    t.jsonb "parking", default: {}
    t.integer "km_per_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plate_state"
    t.boolean "acknowledged"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "phone_number"
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.string "gender"
    t.string "password_digest"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "saved_deals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "product_id"], name: "index_saved_deals_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_saved_deals_on_user_id"
  end

end
