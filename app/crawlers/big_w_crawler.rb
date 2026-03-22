# frozen_string_literal: true

class BigWCrawler < ApplicationCrawler
  BASE_URL = 'https://www.bigw.com.au'
  SALE_PATH = '/deals'
  MAX_PAGES = 10
  MAX_RETRIES = 2
  TIMEOUT = 20

  attr_reader :data

  def initialize
    super(BASE_URL)
    @current_page = 1
    @has_more = true
    @data = []
  end

  def crawl_all
    while has_more && current_page <= MAX_PAGES
      response = fetch_with_retry(SALE_PATH, params)
      break unless response

      results = parse(response)
      break if results.empty?

      @data += results
      @data = @data.uniq { |p| p['id'] }
    end

    self
  end

  private

  attr_reader :current_page, :has_more

  def fetch_with_retry(path, req_params)
    retries = 0
    begin
      client.get(path, req_params) do |req|
        req.headers['Accept'] = 'text/html,application/xhtml+xml'
        req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        req.options.timeout = TIMEOUT
        req.options.open_timeout = 10
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      retries += 1
      Rails.logger.warn "BigWCrawler timeout (attempt #{retries}/#{MAX_RETRIES}): #{e.message}"
      retry if retries < MAX_RETRIES
      Rails.logger.error "BigWCrawler giving up after #{MAX_RETRIES} retries"
      nil
    end
  end

  def parse(response)
    return [] unless response&.success?

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
      'old_price' => old_price.positive? ? old_price : nil,
      'image_url' => image_el&.[]('src') || image_el&.[]('data-src'),
      'store_path' => link
    }
  end

  def params
    { page: current_page }
  end

  def client
    @client ||= Faraday.new(url: BASE_URL) do |faraday|
      faraday.request :url_encoded
      faraday.options.timeout = TIMEOUT
      faraday.options.open_timeout = 10
      faraday.adapter Faraday.default_adapter
    end
  end
end
