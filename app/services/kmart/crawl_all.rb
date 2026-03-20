# frozen_string_literal: true

module Kmart
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
      crawler = KmartCrawler.new
      crawler.crawl_all

      @attributes = crawler.data.map { |result| build_attributes(result) }.compact
    end

    def build_attributes(result)
      name = result['name'] || result.dig('basicInfo', 'name')
      return if name.blank?

      price = extract_price(result)
      old_price = extract_old_price(result)
      store_product_id = result['id'] || result['productId'] || result.dig('basicInfo', 'id')
      return if store_product_id.blank?

      url_path = result['urlPath'] || result.dig('basicInfo', 'urlPath') || "/product/#{store_product_id}"
      image_url = extract_image(result)
      brand = result['brand'] || result.dig('basicInfo', 'brand')
      category = result.dig('categories', 0, 'name') || 'sale'

      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: store_product_id.to_s,
        brand: brand&.downcase,
        image_url:,
        store_path: url_path,
        store: Product::KMART,
        categories: [category.downcase],
        description: refine_description(name, [category.downcase])
      }
    end

    def extract_price(result)
      (result.dig('price', 'current') ||
        result.dig('price', 'selling') ||
        result['price']).to_f
    end

    def extract_old_price(result)
      (result.dig('price', 'was') ||
        result.dig('price', 'original') ||
        result.dig('price', 'previous') || 0).to_f
    end

    def extract_image(result)
      result['imageUrl'] ||
        result.dig('images', 0, 'url') ||
        result.dig('images', 0)
    end

    def upsert_products
      return if attributes.empty?

      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      remove_products_for_store(store: Product::KMART, keep_store_product_ids: store_product_ids)
    end
  end
end
