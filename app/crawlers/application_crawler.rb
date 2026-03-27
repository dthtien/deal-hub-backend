class ApplicationCrawler
  TOTAL_PAGES_UNKNOWN = -1
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'.freeze
  attr_reader :data

  def initialize(url)
    @url = url
    @data = []
  end

  def crawl
    raise NotImplementedError
  end

  private

  attr_reader :url


  def client
    @client ||= Faraday.new(url:) do |faraday|
      faraday.request :url_encoded
      faraday.headers['User-Agent'] = USER_AGENT
      faraday.options.timeout = 15
      faraday.options.open_timeout = 10
      faraday.adapter Faraday.default_adapter
    end
  end
end
