class ApplicationCrawler
  TOTAL_PAGES_UNKNOWN = -1

  def initialize(url)
    @url = url
  end

  def crawl
    raise NotImplementedError
  end

  private

  attr_reader :url


  def client
    @client ||= Faraday.new(url:) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end
  end
end
