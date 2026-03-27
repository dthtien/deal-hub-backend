# frozen_string_literal: true

class BeginningBoutiqueCrawler < ApplicationCrawler
  BASE_URL = 'https://www.beginningboutique.com.au'
  PER_PAGE = 250
  MAX_PAGES = 10
  COLLECTIONS = %w[sale].freeze

  attr_reader :data

  def initialize
    super(BASE_URL)
    @data = []
  end

  def crawl_all
    COLLECTIONS.each do |collection|
      page = 1
      loop do
        response = client.get("/collections/#{collection}/products.json", { limit: PER_PAGE, page: page })
        break unless response.success?

        products = JSON.parse(response.body)['products'] || []
        break if products.empty?

        @data += products.map { |p| parse_product(p) }.compact
        @data = @data.uniq { |p| p['id'] }
        break if products.size < PER_PAGE || page >= MAX_PAGES

        page += 1
      end
    end
    self
  rescue => e
    Rails.logger.error "BeginningBoutiqueCrawler error: #{e.message}"
    self
  end

  private

  def parse_product(p)
    variant = p['variants']&.first
    return nil unless variant

    price = variant['price'].to_f
    compare_price = variant['compare_at_price'].to_f
    return nil if price.zero?

    image_url = p.dig('images', 0, 'src')

    {
      'id'         => p['id'].to_s,
      'title'      => p['title'],
      'variants'   => p['variants'],
      'images'     => p['images'],
      'handle'     => p['handle'],
      'vendor'     => p['vendor'],
      'tags'       => p['tags'],
      'price'      => price,
      'old_price'  => compare_price.positive? ? compare_price : nil,
      'image_url'  => image_url,
      'store_path' => "/products/#{p['handle']}"
    }
  end

  def client
    @client ||= Faraday.new(url: BASE_URL) do |f|
      f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      f.options.timeout = 20
      f.adapter Faraday.default_adapter
    end
  end
end
