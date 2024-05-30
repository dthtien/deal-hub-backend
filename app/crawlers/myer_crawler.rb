# frozen_string_literal: true

class MyerCrawler < ApplicationCrawler
  PAGE_SIZE = 100
  attr_reader :data

  def initialize
    super('https://api-online.myer.com.au')
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
    result = JSON.parse(response.body)
    total_count = result['productTotalCount']
    if total_pages == TOTAL_PAGES_UNKNOWN && total_count.positive?
      @total_pages = (total_count / PAGE_SIZE.to_f).ceil - 1
    end

    @data += result['productList'] if result['productList']
  end

  def fetch_list
    retry_count ||= 0
    @current_page += 1
    client.get('v3/product/cat/byseo/sale-all', params) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    end
  rescue StandardError => _e
    if retry_count < 3
      retry_count += 1
      retry
    end
    OpenStruct.new(body: '{}')
  end

  def params
    {
      pageNumber: current_page,
      pageSize: PAGE_SIZE,
      facets: nil,
      categoryUrlId: '/offers/sale-all',
      variants: 'ff91b023-bce8-436e-a512-b7d2c365258e:46213aff-6657-45b4-b17b-84d0c5a9f725'
    }
  end
end
