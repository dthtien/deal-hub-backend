# frozen_string_literal: true

module UniversalStore
  class CrawlAll < Base
    def initialize
      super
      @attributes = []
    end

    def call
      crawler_and_build
      upsert_products
      remove_old_products
    end

    private

    attr_reader :attributes

    def crawler_and_build
      crawler.crawl_all

      @attributes = crawler.data.map { |result| build_attributes(result) }.compact
                            .uniq { |a| a[:store_product_id] }
    end

    def build_attributes(result)
      name = result['name']
      return if name.blank?

      price = result['price'].to_f
      return if price.zero?

      old_price = result['old_price'].to_f
      # Skip if no discount
      return unless old_price > price

      categories = result['tags'] || []

      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['id'].to_s,
        brand: result['vendor']&.downcase,
        image_url: result['image_url'],
        store_path: result['store_path'],
        store: Product::UNIVERSAL_STORE,
        categories: categories,
        description: refine_description(name, categories)
      }
    end

    def upsert_products
      return if attributes.empty?
      upsert_with_price_history(attributes, store: Product::UNIVERSAL_STORE)
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      remove_products_for_store(store: Product::UNIVERSAL_STORE, keep_store_product_ids: store_product_ids)
    end
  end
end
