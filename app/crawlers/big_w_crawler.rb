# frozen_string_literal: true

class BigWCrawler < ApplicationCrawler
  BASE_URL = 'https://www.bigw.com.au'
  # /deals now answers 301 to this collection page. It is a Next.js page: the
  # listing is in the embedded __NEXT_DATA__ JSON (props.pageProps.results.organic),
  # 48 tiles per page, and the store exposes at most 2000 results (42 pages).
  SALE_PATH = '/collection/deals'
  MAX_PAGES = 10
  PAGE_DELAY = 1 # seconds between listing pages
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
      sleep(PAGE_DELAY) if has_more && current_page <= MAX_PAGES
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
      # Without the first page the crawl is empty and the service would delete
      # every Big W product. Let the job see the network error instead.
      raise e if current_page == 1

      nil
    end
  end

  def parse(response)
    listing, paths = read_page(response)
    products = listing ? listing['results'].filter_map { |item| extract_product(item, paths) } : []

    if products.empty?
      message = "BigWCrawler - no products on page #{current_page} " \
                "(status #{response.status}, location #{response.headers['location'].inspect})"
      # Fail loudly on the first page, so that a moved or blocked listing does not
      # look like a successful crawl with zero products.
      raise message if current_page == 1

      Rails.logger.warn message
      @has_more = false
      return []
    end

    # pageCount is the store's own page total (42 today). If it ever goes missing,
    # keep going: the loop still ends at MAX_PAGES or at the first page without products.
    page_count = listing['pageCount'].to_i
    @has_more = page_count.zero? || current_page < page_count
    @current_page += 1

    products
  end

  # Returns [listing, paths]: the listing hash from __NEXT_DATA__ and a map of
  # product code => product path taken from the tile links (the JSON has no slug).
  def read_page(response)
    return unless response.success?

    doc = Nokogiri::HTML(response.body.to_s, nil, 'UTF-8')
    json = doc.at_css('script#__NEXT_DATA__')&.text
    return if json.blank?

    listing = JSON.parse(json).dig('props', 'pageProps', 'results', 'organic')
    return unless listing.is_a?(Hash) && listing['results'].is_a?(Array)

    paths = doc.css('a[data-product-code][href]').each_with_object({}) do |link, memo|
      memo[link['data-product-code']] ||= link['href']
    end

    [listing, paths]
  rescue JSON::ParserError, TypeError => e
    Rails.logger.error "BigWCrawler parse error: #{e.message}"
    nil
  end

  def extract_product(item, paths)
    # Sponsored tiles are paid placements that change from one request to the next
    return nil if item['type'] == 'sponsored'

    code = item['code'].to_s
    name = item.dig('information', 'name').to_s.strip
    derived = item['derived'] || {}
    # Amounts are in cents
    price_cents = derived.dig('priceRange', 'min', 'amount').to_i
    return nil if code.blank? || name.blank? || price_cents <= 0

    {
      'id' => code,
      'name' => name,
      'price' => price_cents / 100.0,
      'old_price' => old_price(derived, price_cents),
      'image_url' => image_url(derived),
      'store_path' => paths[code] || "/product/#{name.parameterize}/p/#{code}"
    }
  rescue TypeError, NoMethodError => e
    Rails.logger.warn "BigWCrawler skipped a product: #{e.message}"
    nil
  end

  # CLEARANCE and PRICE DROP products carry wasPrice, "SAVE $x" tiles only carry
  # the saving. A product sold at a price range ("$37.49 - $49.99") gets no
  # previous price: its saving does not always belong to the lowest price.
  def old_price(derived, price_cents)
    was_cents = derived['wasPrice'].to_i
    if was_cents.zero? && !price_range?(derived, price_cents)
      savings_cents = derived.dig('savingsRange', 'min', 'amount').to_i
      was_cents = price_cents + savings_cents if savings_cents.positive?
    end

    was_cents > price_cents ? was_cents / 100.0 : nil
  end

  def price_range?(derived, price_cents)
    max_cents = derived.dig('priceRange', 'max', 'amount').to_i
    max_cents.positive? && max_cents != price_cents
  end

  def image_url(derived)
    images = derived.dig('media', 'image') || {}
    path = images['medium'].presence || images['large'].presence || images['small'].presence
    return nil if path.blank?

    path.start_with?('http') ? path : "#{BASE_URL}#{path}"
  end

  def params
    # Page 1 is the bare collection URL, the next pages are ?page=2, ?page=3, ...
    current_page > 1 ? { page: current_page } : {}
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
