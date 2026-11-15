# frozen_string_literal: true

# Myer's JSON listing API (api-online.myer.com.au/v3/product/cat/byseo/...) answers
# 404 "Page not found" since 2026-07. The public sale page is server rendered and
# embeds the same listing payload (productTotalCount, productList) in its
# __NEXT_DATA__ script, 48 products per page, paginated with ?pageNumber=N.
class MyerCrawler < ApplicationCrawler
  LISTING_PATH = 'c/offers/sale-all'
  PAGE_SIZE = 48
  MAX_PAGES = 20
  MAX_RETRIES = 3
  PAGE_DELAY = 1 # seconds between listing pages
  # Stand-in for a response when every attempt raised (timeout, connection reset...)
  FailedResponse = Struct.new(:status, :body)
  attr_reader :data

  def initialize
    super('https://www.myer.com.au')
    @total_pages = TOTAL_PAGES_UNKNOWN
    @current_page = 0
    @data = []
  end

  def crawl_all
    while current_page.zero? || current_page < total_pages
      results = parse fetch_list
      break if results.empty?

      @data += results
      @data = @data.uniq { |product| product['id']}
      yield results if block_given?
    end

    self
  end

  private

  attr_reader :total_pages, :current_page

  def parse(response)
    result = listing_from(response.body)
    total_count = result['productTotalCount']
    if total_pages == TOTAL_PAGES_UNKNOWN && total_count.nil?
      raise "MyerCrawler - first page has no productTotalCount (status #{response.status.inspect}): #{response.body.to_s.truncate(200)}"
    end
    if total_pages == TOTAL_PAGES_UNKNOWN && total_count.positive?
      per_page = result['productsPerPage'].to_i
      per_page = PAGE_SIZE unless per_page.positive?
      all_pages = (total_count / per_page.to_f).ceil
      @total_pages = all_pages > MAX_PAGES ? MAX_PAGES : all_pages
    end

    products = result['productList'] || []
    if products.empty?
      # crawl_all stops here, so say why: a refused or changed page must not look like a short listing
      Rails.logger.error "MyerCrawler - page #{current_page} returned no products (status #{response.status.inspect}), stopping with #{data.size} products collected"
    end
    products
  end

  # The listing is the dehydrated react-query entry whose key starts with "category",
  # e.g. ["category", "/offers/sale-all", 1, [], "relevance"].
  def listing_from(html)
    script = Nokogiri::HTML(html.to_s, nil, 'UTF-8').at_css('script#__NEXT_DATA__')
    return {} if script.nil?

    queries = JSON.parse(script.text).dig('props', 'pageProps', 'dehydratedState', 'queries')
    query = Array(queries).find { |q| Array(q['queryKey']).first == 'category' }
    listing = query&.dig('state', 'data')
    listing.is_a?(Hash) ? listing : {}
  rescue JSON::ParserError, TypeError
    {}
  end

  def fetch_list
    @current_page += 1
    sleep PAGE_DELAY if current_page > 1
    attempts = 0
    begin
      client.get(LISTING_PATH, params) do |req|
        req.headers['Accept'] = 'text/html,application/xhtml+xml'
        req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
      end
    rescue StandardError => e
      attempts += 1
      retry if attempts <= MAX_RETRIES

      Rails.logger.error "MyerCrawler - page #{current_page} failed after #{attempts} attempts: #{e.class} #{e.message}"
      FailedResponse.new(nil, '')
    end
  end

  # The first page is the bare listing URL, exactly as the site links to it.
  def params
    current_page > 1 ? { pageNumber: current_page } : {}
  end
end
