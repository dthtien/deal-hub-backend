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

      all = crawler.data.map { |result| build_attributes(result) }.compact

      # Dedupe: same product name → keep lowest-priced variant
      @attributes = all
        .group_by { |a| a[:name]&.downcase&.strip }
        .values
        .map { |variants| variants.min_by { |v| v[:price].to_f } }
        .uniq { |a| a[:store_product_id] }
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
      upsert_with_price_history(attributes, store: Product::THE_ICONIC)
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      remove_products_for_store(store: Product::THE_ICONIC, keep_store_product_ids: store_product_ids)
    end
  end
end
