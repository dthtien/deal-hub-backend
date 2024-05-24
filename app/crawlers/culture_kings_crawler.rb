# frozen_string_literal: true

class CultureKingsCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://22mg8hzkho-dsn.algolia.net')
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

  def algolia_credentials
    @algolia_credentials ||= {
      'x-algolia-agent' => 'Algolia for JavaScript (4.12.2); Browser (lite); JS Helper (3.7.0); react (17.0.1); react-instantsearch (6.22.0)',
      'X-Algolia-Api-Key' => '120a2dd1a67e962183768696b750a52c',
      'X-Algolia-Application-Id' => '22MG8HZKHO'
    }
  end

  def fetch_list
    client.post("/1/indexes/*/queries?#{algolia_credentials.to_param}") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = query_object.to_json
    end
  end

  def parse(response)
    result = JSON.parse(response.body)['results'].first

    @total_pages = result['nbPages'] if total_pages == TOTAL_PAGES_UNKNOWN
    @current_page += 1
    result['hits']
  end

  def query_object
    {
      requests: [
        {
          indexName: 'shopify_production_products_mark_down',
          params: params.to_param
        }
      ]
    }
  end

  def params
    {
      filters: sale_filter,
      hitsPerPage: 100,
      page: current_page
    }
  end

  def sale_filter
    '(inStock:true OR isForcedSoldOut:1 OR isStayInCollection:1) AND isOnline:true AND (NOT isNfs:true) AND collectionHandles:all-sale'
  end
end
