# frozen_string_literal: true

class NikeCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://api.nike.com/cic/browse/v2')
    @total_pages = TOTAL_PAGES_UNKNOWN
    @current_page = start_endpoint
    @data = []
  end

  def crawl_all
    while current_page.present?
      results = parse fetch_list
      break if results.empty?

      @data += results
      @data = @data.uniq
      yield results if block_given?
    end

    self
  end

  private

  attr_reader :total_pages, :current_page

  def fetch_list
    client.get("?#{params.to_param}") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    end
  end

  def parse(response)
    result = JSON.parse(response.body)['data']['products']
    page = result['pages']
    if page.blank?
      @current_page = nil
    else
      @total_pages = result['pages']['totalPages'] if total_pages == TOTAL_PAGES_UNKNOWN
      @current_page = page['next']
    end
    result['products']
  end

  def query_object
    {
      requests: [
        {
          indexName: 'hypedc_au_prd_products',
          params:
        }
      ]
    }
  end

  def start_endpoint
    '/product_feed/rollup_threads/v2?filter=marketplace(AU)&filter=language(en-GB)&filter=employeePrice(true)&filter=attributeIds(5b21a62a-0503-400c-8336-3ccfbff2a684)&anchor=48&consumerChannelId=d9a5bc42-4b9c-4976-858a-f159cf99c647&count=24&sort=productInfo.merchPrice.currentPriceDesc'
  end

  def params
    {
      queryid: 'products',
      anonymousId: '67CF9FB6E026176DC9F72AC479834E80',
      country: 'au',
      endpoint: current_page,
      language: 'en-GB'
    }
  end
end
