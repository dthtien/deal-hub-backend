# frozen_string_literal: true

module Asos
  class CrawlAll < Base
    IGNORABLE_WORDS = %w[bikini swimwear bra underwear lingerie bodysuit].freeze
    URLS = {
      men: 'https://www.asos.com/api/product/search/v2/categories/28233',
      women: 'https://www.asos.com/api/product/search/v2/categories/28040'
    }.freeze

    def initialize
      super
      @attributes = []
    end

    def call
      URLS.each do |gender, url|
        crawler_and_build(url, gender)
      end

      upsert_products
      remove_old_products
    end

    private

    attr_reader :attributes

    def crawler_and_build(url, category)
      crawler = AsosCrawler.new(url)
      crawler.crawl_all

      @attributes += crawler.data.map { |result| build_attributes(result, category) }.compact
    end

    def build_attributes(result, category)
      name = result['name']

      return if ignore_product?(name)

      price_data = result['price']
      price = price_data.dig('current', 'value').to_f
      old_price = price_data.dig('previous', 'value').to_f
      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['id'],
        brand: result['brandName']&.downcase,
        image_url: "https://#{result['imageUrl']}",
        store_path: result['url'],
        store: Product::ASOS,
        categories: [category],
        description: refine_description(name, [category])
      }
    end

    def ignore_product?(name)
      name.blank? || IGNORABLE_WORDS.any? { |word| name.downcase.include?(word) }
    end

    def uniq_attributes
      attributes.uniq { |a| a[:store_product_id] }
    end

    def upsert_products
      Product.upsert_all(uniq_attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::ASOS)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end

