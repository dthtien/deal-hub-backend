# frozen_string_literal: true

class UniversalStoreCrawler < ApplicationCrawler
  BASE_URL = 'https://www.universalstore.com'
  STORE_URL = 'https://www.universalstore.com.au'
  PER_PAGE = 250
  MAX_PAGES = 20

  attr_reader :data

  def initialize
    super(BASE_URL)
    @current_page = 1
    @data = []
  end

  def crawl_all
    loop do
      response = client.get('/collections/sale/products.json', { limit: PER_PAGE, page: @current_page })
      break unless response&.success?

      products = JSON.parse(response.body)['products'] || []
      break if products.empty?

      @data += products.map { |p| parse_product(p) }.compact
      @data = @data.uniq { |p| p['id'] }

      break if products.size < PER_PAGE || @current_page >= MAX_PAGES
      @current_page += 1
    end
    self
  rescue => e
    Rails.logger.error "UniversalStoreCrawler error: #{e.message}"
    self
  end

  private

  def parse_product(p)
    variant = p['variants']&.first
    return nil unless variant

    price = variant['price'].to_f
    return nil if price.zero?

    compare_price = variant['compare_at_price'].to_f
    image_url = p.dig('images', 0, 'src')
    tags = p['tags']&.reject { |t| t.length > 40 }&.first(3) || []

    {
      'id'         => p['id'].to_s,
      'name'       => p['title'],
      'price'      => price,
      'old_price'  => compare_price.positive? ? compare_price : nil,
      'image_url'  => image_url,
      'store_path' => "/products/#{p['handle']}",
      'vendor'     => p['vendor'],
      'tags'       => tags
    }
  end

  def client
    @client ||= Faraday.new(url: BASE_URL) do |f|
      f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
      f.options.timeout = 20
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end
  end
end
