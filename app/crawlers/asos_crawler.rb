# frozen_string_literal: true

class AsosCrawler < ApplicationCrawler
  MAX_LIMIT = 200
  MAX_OFFSET = 2000

  def initialize(url)
    super(url)
    @data = []
    @max_offset = TOTAL_PAGES_UNKNOWN
    @offset = 0
  end

  def crawl_all
    while offset.zero? || offset < max_offset
      puts "Fetching page #{offset}/#{max_offset}"
      results = parse(fetch_list)
      break if results.empty?

      @data += results
      @data = @data.uniq { |product| product['id'] }
    end
  end

  def fetch_list
    client.get(url, params) do |req|
      req.headers['Content-Type'] = 'application/json'
    end
  end

  private

  attr_reader :max_offset, :offset

  def parse(response)
    result = JSON.parse(response.body)
    @max_offset = result['itemCount'] > MAX_OFFSET ? MAX_OFFSET : result['itemCount']
    @offset += MAX_LIMIT
    result['products'].uniq
  end

  def params
    {
      offset:,
      store: 'AU',
      currency: 'AUD',
      country: 'AU',
      lang: 'en-AU',
      limit: MAX_LIMIT
    }
  end
end
