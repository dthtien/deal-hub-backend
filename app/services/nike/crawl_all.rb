# frozen_string_literal: true

module Nike
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

      @attributes += crawler.data.map { |result| build_attributes(result) }.compact
    end

    def build_attributes(result)
      name = result['title']
      return if ignore_product?(name)

      price = result['price']['currentPrice'].to_f
      old_price = result['price']['fullPrice'].to_f
      categories = [result['productType'].downcase]
      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['id'],
        brand: 'nike',
        image_url: result['images']['portraitURL'],
        store_path: result['url'].gsub('{countryLang}', 'au'),
        store: Product::NIKE,
        description: refine_description(result['subtitle'], categories),
        categories:
      }
    end

    def ignore_product?(name)
      name.blank? ||
        name.downcase.include?('bikini') ||
        name.downcase.include?('swimwear') ||
        name.downcase.include?('underwear') ||
        name.downcase.include?('bra')
    end

    def upsert_products
      Product.upsert_all(attributes, unique_by: %i[store_product_id store])
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::NIKE)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end
