class RemoveAllForeignKeys < ActiveRecord::Migration[8.0]
  def up
    # Remove all FKs — use indexes only for performance, no DB-level constraints
    remove_foreign_key "collection_items", "collections" if foreign_key_exists?("collection_items", "collections")
    remove_foreign_key "collection_items", "products"    if foreign_key_exists?("collection_items", "products")
    remove_foreign_key "comments", "products"            if foreign_key_exists?("comments", "products")
    remove_foreign_key "deal_ratings", "products"        if foreign_key_exists?("deal_ratings", "products")
    remove_foreign_key "votes", "products"               if foreign_key_exists?("votes", "products")

    # Ensure indexes exist for all association columns (for query performance)
    add_index "collection_items", "collection_id", if_not_exists: true
    add_index "collection_items", "product_id",    if_not_exists: true
    add_index "comments",         "product_id",    if_not_exists: true
    add_index "deal_ratings",     "product_id",    if_not_exists: true
    add_index "votes",            "product_id",    if_not_exists: true
  end

  def down
    add_foreign_key "collection_items", "collections"
    add_foreign_key "collection_items", "products", on_delete: :cascade
    add_foreign_key "comments",         "products", on_delete: :cascade
    add_foreign_key "deal_ratings",     "products", on_delete: :cascade
    add_foreign_key "votes",            "products", on_delete: :cascade
  end
end
