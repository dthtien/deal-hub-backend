class OfficeWorksCrawler < ApplicationCrawler
  TOTAL_PAGES_UNKNOWN = -1
  attr_reader :data

  def initialize
    super('https://k535caawve-dsn.algolia.net')
    @total_pages = TOTAL_PAGES_UNKNOWN
    @current_page = 0
    @data = []
  end

  def crawl_all
    while current_page.zero? || current_page < total_pages
      results = parse fetch_list
      break if results.empty?

      @data += results
      yield results if block_given?
    end

    self
  end

  def crawl_price(sku)
    response = client.get("https://www.officeworks.com.au/catalogue-app/api/prices/#{sku}")
    JSON.parse(response.body)
  end

  private

  attr_reader :total_pages, :current_page

  def fetch_list
    client.post("/1/indexes/*/queries?#{algolia_credentials.to_param}") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = query_object.to_json
    end
  end

  def algolia_credentials
    @algolia_credentials ||= {
      'x-algolia-agent' => 'Algolia for JavaScript (3.35.1); Browser (lite); react (16.14.0); react-instantsearch (5.7.0); JS Helper (2.28.1)',
      'x-algolia-application-id': 'K535CAAWVE',
      'x-algolia-api-key': '8a831febe0110932cfa06ff0e2024b4f'
    }
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
          indexName: 'prod-product-wc-bestmatch-personal',
          params: params.to_param
        }
      ]
    }
  end

  def params
    {
      hitsPerPage: 100,
      maxValuesPerFacet: 10,
      page: @current_page,
      analyticsTags: '["browse"]',
      filters: '(categorySeoPaths:"price-checked-price-dropped")',
      ruleContexts: '["price-checked-price-dropped","price-checked-price-dropped","ANONYMOUS"]',
      facetFilters: '[["categorySeoPaths:price-checked-price-dropped"]]'
    }
  end
end
