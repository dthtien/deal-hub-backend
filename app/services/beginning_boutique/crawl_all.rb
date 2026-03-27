# frozen_string_literal: true

module BeginningBoutique
  class CrawlAll < Base
    IGNORABLE_WORDS = %w[bikini swimwear bra underwear lingerie bodysuit brief panty].freeze

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
        .compact.uniq { |attribute| attribute[:store_product_id] }
    end

    def build_attributes(result)
      name = result['title']
      return if ignore_product?(name)

      variant = result['variants']&.first
      return unless variant

      price = variant['price'].to_f
      return if price.zero?

      old_price = variant['compare_at_price'].to_f
      return unless old_price > price

      categories = result['tags']&.select { |t| t.length < 30 }&.first(3) || []

      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['id'].to_s,
        brand: result['vendor']&.downcase,
        image_url: result.dig('images', 0, 'src'),
        store_path: "/products/#{result['handle']}",
        store: Product::BEGINNING_BOUTIQUE,
        description: refine_description(name, categories),
        categories: categories
      }
    end

    def ignore_product?(name)
      name.blank? ||
        IGNORABLE_WORDS.any? { |word| name.downcase.include?(word) }
    end

    def upsert_products
      upsert_with_price_history(attributes, store: Product::BEGINNING_BOUTIQUE)
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      remove_products_for_store(store: Product::BEGINNING_BOUTIQUE, keep_store_product_ids: store_product_ids)
    end
  end
end
