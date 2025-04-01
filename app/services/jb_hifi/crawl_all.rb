# frozen_string_literal: true

module JbHifi
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
                              .compact
                              .uniq { |a| a[:store_product_id] }
    end

    def build_attributes(result)
      categories = result['category_hierarchy'].map(&:downcase).uniq
      return if ignore_product?(categories)

      price = result['pricing']['displayPriceInc'].to_f
      old_price = result['pricing']['wasPrice'].to_f
      {
        name: result['title'],
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['sku'].presence || result['product']['id'],
        brand: result['product']['brand']&.downcase,
        image_url: result['product_image'],
        store_path: result['handle'],
        store: Product::JB_HIFI,
        description: refine_description(result['display']['keyFeatures']&.to_sentence, categories),
        categories:
      }
    end

    def ignore_product?(categories)
      categories.any? do |category|
        category.include?('merchandise') || category.include?('figurines')
      end
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::JB_HIFI)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end

