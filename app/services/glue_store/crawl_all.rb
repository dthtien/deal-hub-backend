# frozen_string_literal: true

module GlueStore
  class CrawlAll < Base
    IGNORABLE_WORDS = %w[bikini swimwear bra underwear lingerie bodysuit].freeze

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

      @attributes += crawler.data.map { |result| build_attributes(result) }.compact
    end

    def build_attributes(result)
      name = result['title']
      categories = result['tags'].map(&:downcase).uniq
      return if ignore_product?(name, categories)

      price = result['price'].to_f
      old_price = result['compare_at_price'].to_f
      {
        name: result['title'],
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['sku'].presence,
        brand: result['vendor'].downcase,
        image_url: result['product_image'],
        store_path: result['handle'],
        store: Product::GLUE_STORE,
        description: result['body_html_safe'].strip,
        categories: refine_categories(result['tags'])
      }
    end

    def refine_categories(tags)
      return if tags.blank?

      tags.uniq.reject { |tag| digits?(tag) }.map do |tag|
        tag.include?('|') ? tag.downcase.split('|').last : tag.downcase
      end.uniq
    end

    def digits?(str)
      !str[/\d/].nil?
    end

    def ignore_product?(name, categories)
      name.blank? ||
        IGNORABLE_WORDS.any? { |word| name.include?(word) } ||
        invalid_category?(categories)
    end

    def invalid_category?(categories)
      categories.any? do |category|
        IGNORABLE_WORDS.any? { |word| category.include?(word) }
      end
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

