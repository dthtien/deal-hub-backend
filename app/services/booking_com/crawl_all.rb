# frozen_string_literal: true

module BookingCom
  class CrawlAll < Base
    CATEGORIES = %w[travel accommodation].freeze

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
      crawler = BookingComCrawler.new
      crawler.crawl_all

      @attributes = crawler.data.map { |result| build_attributes(result) }.compact
    end

    def build_attributes(result)
      name = result['name']
      return if name.blank?

      price = result['price'].to_f
      return if price.zero?

      store_product_id = result['id']
      return if store_product_id.blank?

      store_path = result['store_path']
      return if store_path.blank?

      location = result['location']
      full_name = location.present? ? "#{name} - #{location}" : name

      {
        name: full_name,
        price:,
        old_price: 0.0,
        discount: 0,
        store_product_id: store_product_id.to_s,
        brand: nil,
        image_url: result['image_url'],
        store_path:,
        store: Product::BOOKING_COM,
        categories: CATEGORIES,
        description: refine_description(full_name, CATEGORIES)
      }
    end

    def upsert_products
      return if attributes.empty?

      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::BOOKING_COM)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end
