# frozen_string_literal: true

module TheIconic
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

      @attributes = crawler.data
        .map { |result| build_attributes(result) }.compact.uniq do |attribute|
          attribute[:store_product_id]
        end
    end

    def build_attributes(result)
      return if ignore_product?(result)

      result.merge(
        discount: calculate_discount(result[:old_price], result[:price]),
        store: Product::THE_ICONIC,
        description: refine_description(result[:description], result[:categories])
      )
    end

    def ignore_product?(result)
      name = result[:name].to_s.downcase

      name.blank? ||
        name.include?('bikini') ||
        name.include?('swimwear') ||
        name.include?('bodysuit') ||
        name.include?('underwear') ||
        name.include?('bra')
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::THE_ICONIC)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end
