# frozen_string_literal: true

module BigW
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
      crawler = BigWCrawler.new
      crawler.crawl_all

      @attributes = crawler.data.map { |result| build_attributes(result) }.compact
    end

    def build_attributes(result)
      name = result['name']
      return if name.blank?

      price = result['price'].to_f
      return if price.zero?

      old_price = result['old_price'].to_f
      store_product_id = result['id']
      return if store_product_id.blank?

      store_path = result['store_path']
      # Ensure store_path is relative
      if store_path&.start_with?('http')
        store_path = URI.parse(store_path).path rescue store_path
      end

      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: store_product_id.to_s,
        brand: nil,
        image_url: result['image_url'],
        store_path:,
        store: Product::BIG_W,
        categories: ['sale', 'clearance'],
        description: refine_description(name, ['sale', 'clearance'])
      }
    end

    def upsert_products
      return if attributes.empty?

      upsert_with_price_history(attributes, store: Product::BIG_W)
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      remove_products_for_store(store: Product::BIG_W, keep_store_product_ids: store_product_ids)
    end
  end
end
