# frozen_string_literal: true

class UpdateCollectionsJob < ApplicationJob
  queue_as :default

  def perform
    Collection.active.each do |collection|
      begin
        update_collection(collection)
      rescue => e
        Rails.logger.error("UpdateCollectionsJob: error for #{collection.name}: #{e.message}")
      end
    end
  end

  private

  def update_collection(collection)
    keywords = extract_keywords(collection)
    return if keywords.empty?

    new_products = find_matching_products(keywords)
    old_ids = collection.collection_items.pluck(:product_id)
    new_ids = new_products.pluck(:id)

    added_count   = (new_ids - old_ids).size
    removed_count = (old_ids - new_ids).size

    CollectionItem.where(collection: collection).delete_all

    new_products.each_with_index do |product, idx|
      CollectionItem.create!(collection: collection, product: product, position: idx + 1)
    end

    collection.touch

    Rails.logger.info("Updated collection #{collection.name}: added #{added_count}, removed #{removed_count}")
  end

  def extract_keywords(collection)
    words = collection.name.downcase.split(/\W+/).reject { |w| w.length < 3 }
    desc_words = collection.description.to_s.downcase.split(/\W+/).reject { |w| w.length < 3 }
    (words + desc_words).uniq.first(3)
  end

  def find_matching_products(keywords)
    scope = Product.where(expired: false)
    conditions = keywords.map { "LOWER(name) LIKE ?" }
    values = keywords.map { |kw| "%#{kw}%" }
    scope.where(conditions.join(' OR '), *values)
         .order(deal_score: :desc)
         .limit(10)
  end
end
