# frozen_string_literal: true

class BigWCrawler < ApplicationCrawler
  BASE_URL = 'https://www.bigw.com.au'
  SALE_PATH = '/category/clearance-sale'

  attr_reader :data

  def initialize
    super(BASE_URL)
    @current_page = 1
    @has_more = true
    @data = []
  end

  def crawl_all
    while has_more
      results = parse(fetch_list)
      break if results.empty?

      @data += results
      @data = @data.uniq { |p| p['id'] }
    end

    self
  end

  private

  attr_reader :current_page, :has_more

  def fetch_list
    client.get(SALE_PATH, params) do |req|
      req.headers['Accept'] = 'text/html,application/xhtml+xml'
      req.headers['User-Agent'] = 'Mozilla/5.0 (compatible; DealHubBot/1.0)'
    end
  end

  def parse(response)
    doc = Nokogiri::HTML(response.body)
    products = []

    doc.css('[data-testid="product-tile"], .product-tile, .ProductTile, [class*="product-tile"]').each do |card|
      product = extract_product(card)
      products << product if product
    end

    # Try alternative selectors if none found
    if products.empty?
      doc.css('article[class*="product"], div[class*="ProductCard"]').each do |card|
        product = extract_product(card)
        products << product if product
      end
    end

    # Check for next page
    next_page = doc.at_css('[aria-label="Next page"], .pagination-next, [rel="next"]')
    @has_more = next_page && !next_page['disabled']
    @current_page += 1

    products
  rescue => e
    Rails.logger.error "BigWCrawler parse error: #{e.message}"
    @has_more = false
    []
  end

  def extract_product(card)
    name_el = card.at_css('[class*="product-title"], [class*="ProductName"], h2, h3, [class*="name"]')
    price_el = card.at_css('[class*="selling-price"], [class*="Price"], [class*="price"]')
    old_price_el = card.at_css('[class*="was-price"], [class*="WasPrice"], [class*="original-price"], s, del')
    image_el = card.at_css('img')
    link_el = card.at_css('a')

    name = name_el&.text&.strip
    return nil if name.blank?

    price_text = price_el&.text&.strip&.gsub(/[^0-9.]/, '')
    price = price_text.to_f
    return nil if price.zero?

    old_price_text = old_price_el&.text&.strip&.gsub(/[^0-9.]/, '')
    old_price = old_price_text.to_f

    link = link_el&.[]('href')
    product_id = link&.split('/')&.last || name.parameterize

    {
      'id' => product_id,
      'name' => name,
      'price' => price,
      'old_price' => old_price,
      'image_url' => image_el&.[]('src') || image_el&.[]('data-src'),
      'store_path' => link&.start_with?('http') ? link : link
    }
  end

  def params
    { page: current_page }
  end
end
