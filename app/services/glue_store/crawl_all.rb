# frozen_string_literal: true

module GlueStore
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
        name: result['title'],
        price: result['price'],
        store_product_id: result['sku'].presence,
        brand: result['vendor'].downcase,
        image_url: result['product_image'],
        store_path: result['handle'],
        store: Product::GLUE_STORE,
        description: result['body_html_safe'].strip,
        categories: result['tags'].present? && result['tags'].map(&:downcase).uniq
      }
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::GLUE_STORE)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end

