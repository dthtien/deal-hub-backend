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
      results = parse(fetch_list)
      break if results.empty?

      @data += results
      @data = @data.uniq { |p| p['id'] }
    end

    self
  end

  private

  attr_reader :total_pages, :current_page

  def fetch_list
    client.get(SALE_PATH, params) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
    end
  end

  def parse(response)
    result = JSON.parse(response.body)
    products = result.dig('products') || []

    if total_pages == TOTAL_PAGES_UNKNOWN
      total_count = result.dig('pagination', 'total') || result.dig('totalCount') || 0
      calculated_pages = (total_count.to_f / PAGE_SIZE).ceil
      @total_pages = calculated_pages.positive? ? calculated_pages : 1
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
end
