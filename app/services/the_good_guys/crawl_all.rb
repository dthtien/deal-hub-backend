# frozen_string_literal: true

module TheGoodGuys
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

      @attributes += crawler.data.map { |result| build_attributes(result) }.compact.uniq
    end

    def build_attributes(result)
      fields = result['fields']
      name = fields['heading']['stringValue']
      return if name.blank?

      price = fields.dig('price', 'stringValue').to_f
      old_price = fields.dig('wasPrice', 'stringValue').to_f
      description = fields.dig('shortDescription', 'stringValue')
      categories = parse_categories(fields['categories'])
      {
        name:,
        price:,
        old_price: old_price.zero? ? nil : old_price,
        discount: calculate_discount(old_price, price),
        store_product_id: fields.dig('sku', 'stringValue'),
        brand: fields.dig('brand', 'mapValue', 'fields', 'name', 'stringValue'),
        image_url: parse_image_url(fields['images']),
        store_path: fields.dig('productUrl', 'stringValue'),
        store: Product::THE_GOOD_GUYS,
        description: refine_description(description, categories),
        categories:
      }
    end

    def parse_categories(categories)
      list = categories.dig('mapValue', 'fields').values

      list.map do |item|
        item.dig('mapValue', 'fields', 'name', 'stringValue').downcase
      end.last(1)
    end

    def parse_image_url(images)
      image = images.dig('arrayValue', 'values').first

      image.dig('mapValue', 'fields', 'Url', 'stringValue')
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::THE_GOOD_GUYS)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end

