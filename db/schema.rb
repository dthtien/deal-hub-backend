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

ActiveRecord::Schema[7.1].define(version: 2024_05_07_012408) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.index ["categories"], name: "index_products_on_categories", using: :gin
    t.index ["name"], name: "index_products_on_name"
    t.index ["store"], name: "index_products_on_store"
    t.index ["store_product_id", "store"], name: "index_products_on_store_product_id_and_store", unique: true
    t.index ["store_product_id"], name: "index_products_on_store_product_id"
  end

end
