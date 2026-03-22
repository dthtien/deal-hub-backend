# frozen_string_literal: true

class KmartCrawler < ApplicationCrawler
  BASE_URL = 'https://www.kmart.com.au'
  SALE_PATH = '/api/2.0/page/search/'
  PAGE_SIZE = 48

  attr_reader :data

  def initialize
    super(BASE_URL)
    @total_pages = TOTAL_PAGES_UNKNOWN
    @current_page = 0
    @data = []
  end

  def crawl_all
    while current_page.zero? || current_page < total_pages
      response = fetch_list
      break unless response&.success?

      results = parse(response)
      break if results.empty?

      @data += results
      @data = @data.uniq { |p| p['id'] }
    end
    self
  rescue => e
    Rails.logger.error "KmartCrawler error: #{e.message}"
    self
  end

  private

  attr_reader :total_pages, :current_page

  def fetch_list
    retries = 0
    begin
      client.get(SALE_PATH, params) do |req|
        req.headers['Content-Type']  = 'application/json'
        req.headers['Accept']        = 'application/json, text/plain, */*'
        req.headers['User-Agent']    = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
        req.headers['Referer']       = 'https://www.kmart.com.au/sale/'
        req.headers['Origin']        = 'https://www.kmart.com.au'
        req.options.timeout          = 20
        req.options.open_timeout     = 10
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      retries += 1
      Rails.logger.warn "KmartCrawler timeout attempt #{retries}: #{e.message}"
      retry if retries < 2
      Rails.logger.error 'KmartCrawler: giving up'
      nil
    end
  end

  def parse(response)
    return [] unless response&.success?

    result = JSON.parse(response.body)
    products = result['products'] || []

    if total_pages == TOTAL_PAGES_UNKNOWN
      total_count = result.dig('pagination', 'total') || result['totalCount'] || 0
      calculated_pages = (total_count.to_f / PAGE_SIZE).ceil
      @total_pages = [calculated_pages, 1].max
    end

    @current_page += 1
    products
  rescue JSON::ParserError => e
    Rails.logger.error "KmartCrawler parse error: #{e.message}"
    @total_pages = 0
    []
  end

  def params
    {
      pageType: 'category',
      urlPath: '/sale',
      pageSize: PAGE_SIZE,
      pageNumber: current_page
    }
  end

  def client
    @client ||= Faraday.new(url: BASE_URL) do |f|
      f.request :url_encoded
      f.options.timeout = 20
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end
  end
end
