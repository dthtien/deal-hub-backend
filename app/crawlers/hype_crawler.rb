# frozen_string_literal: true

class HypeCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://www.hypedc.com/au/api/')
    @total_pages = TOTAL_PAGES_UNKNOWN
    @current_page = 0
    @data = []
  end

  def crawl_all
    while current_page.zero? || current_page < total_pages
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
    client.post('search/indexes/*/queries') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['accept-language'] = 'en-US,en;q=0.9,vi;q=0.8'
      req.headers['user-agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
      req.body = query_object.to_json
    end
  end

  def parse(response)
    result = JSON.parse(response.body)['data']['results'].first

    @total_pages = result['nbPages'] if total_pages == TOTAL_PAGES_UNKNOWN
    @current_page += 1
    result['hits']
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

  def params
    {
      facetFilters: ['visibleIn.categories:true'],
      facets: ['isDiscounted'],
      hitsPerPage: 100,
      page: current_page
    }
  end
end
