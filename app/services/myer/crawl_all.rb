# frozen_string_literal: true

module Myer
  class CrawlAll < Base
    ASSET_URL = 'https://myer-media.com.au/wcsstore/MyerCatalogAssetStore'
    IMAGE_SIZE = '720x928'
    IGNORABLE_WORDS = %w[bikini swimwear bra underwear lingerie bodysuit brief panty].freeze

    def initialize
      super
      @attributes = []
    end

    def call
      crawler_and_save
      remove_old_products
    end

    private

    attr_reader :attributes

    def crawler_and_save
      crawler.crawl_all do |results|
        data = results.map { |result| build_attributes(result) }.compact
        upsert_products data
        @attributes += data
      end
    end

    def build_attributes(result)
      name = result['name']
      return if ignore_product?(name)

      price = result['priceFrom'].to_f
      old_price = result['listPriceFrom'].to_f
      {
        name:,
        price:,
        old_price:,
        discount: calculate_discount(old_price, price),
        store_product_id: result['id'],
        brand: result['brand'],
        image_url: image_url(result),
        store_path: result['seoToken'],
        store: Product::MYER,
        description: result['merchCategory'],
        categories: build_categories(result)
      }
    end

    def ignore_product?(name)
      name = name.to_s.downcase
      name.blank? || IGNORABLE_WORDS.any? { |word| name.include?(word) }
    end

    def image_url(result)
      images = result['media']
      return if images.blank?

      image = images.first
      return if image.blank?

      url = image['baseUrl']
      url = url.gsub('{{size}}', IMAGE_SIZE)
      "#{ASSET_URL}/#{url}"
    end

    def build_categories(result)
      [result['merchCategory'].split('/').last]
    end

    def upsert_products(data)
      Product.upsert_all(data, unique_by: %i[store_product_id store])
    rescue StandardError => e
      Rails.logger.error e
      ExceptionNotifier.notify_exception(e)
    end

    def remove_old_products
      store_product_ids = attributes.map { |a| a[:store_product_id] }
      Product.where(store: Product::MYER)
             .where.not(store_product_id: store_product_ids).delete_all
    end
  end
end
