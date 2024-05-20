class JbHifiCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://vtvkm5urpx-dsn.algolia.net')
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

  private

  attr_reader :total_pages, :current_page

  def algolia_credentials
    @algolia_credentials ||= {
      'x-algolia-agent' => 'Algolia for JavaScript (4.6.0); Browser; JS Helper (3.13.3); react (16.14.0); react-instantsearch (6.7.0)',
      'X-Algolia-Api-Key' => '1d989f0839a992bbece9099e1b091f07',
      'X-Algolia-Application-Id' => 'VTVKM5URPX'
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
          indexName: 'shopify_products_families',
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
    '"banner_tags.label": "On Sale" AND (price > 0 AND product_published = 1 AND availability.displayProduct = 1) AND onPromotion:true AND (price > 0 AND product_published = 1 AND availability.displayProduct = 1)'
  end
end
