# frozen_string_literal: true

module OfficeWorks
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

      @attributes += crawler.data.map { |result| build_attributes(result) }
    end

    def build_attributes(result)
      {
        name: result['name'],
        price: result['price'].to_f / 100,
        discount: 0,
        store_product_id: result['sku'],
        brand: result['brand']&.downcase,
        available_states: result['availState'].uniq,
        image_url: result['image'],
        store_path: result['seoPath'],
        store: Product::OFFICE_WORKS,
        description: result['descriptionShort'],
        categories: result['categories'].map(&:downcase).uniq
      }
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::OFFICE_WORKS)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end
