# frozen_string_literal: true

class GlueStoreCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://aw7pfg4ytn-dsn.algolia.net/')
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
      'x-algolia-agent' => 'Algolia for JavaScript (4.17.0); Browser (lite); instantsearch.js (4.56.0); Shopify Integration; JS Help',
      'X-Algolia-Api-Key' => 'edc5bc922fe2c5dfcdcc46dff7371f62',
      'X-Algolia-Application-Id' => 'AW7PFG4YTN'
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
          indexName: 'glueprodau_products',
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
    'collections:"sale" AND NOT tags:algolia30days'
  end
end
