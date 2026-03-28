# frozen_string_literal: true

require 'net/http'
require 'uri'

class CouponScraper
  COUPON_PATTERN = /\b[A-Z0-9]{4,12}\b/
  DISCOUNT_KEYWORDS = /discount|coupon|promo|code|off|save|deal/i

  TARGETS = [
    { url: 'https://www.asos.com/au/sale/', store: 'ASOS' },
    { url: 'https://www.culturekings.com.au/promo', store: 'Culture Kings' }
  ].freeze

  def self.call
    new.run
  end

  def run
    results = []
    TARGETS.each do |target|
      begin
        codes = scrape(target[:url], target[:store])
        results.concat(codes)
      rescue => e
        Rails.logger.warn("CouponScraper - failed to scrape #{target[:url]}: #{e.message}")
      end
    end
    results
  end

  private

  def scrape(url, store)
    html = fetch_html(url)
    return [] if html.nil?

    codes = extract_codes(html)
    saved = []

    codes.each do |code|
      next if Coupon.exists?(store: store, code: code)

      coupon = Coupon.create!(
        store: store,
        code: code,
        description: "Scraped coupon from #{store}",
        discount_type: 'percent',
        active: true
      )
      saved << coupon
      Rails.logger.info("CouponScraper - saved coupon #{code} for #{store}")
    end

    saved
  end

  def fetch_html(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Mozilla/5.0 (compatible; OzVFY-bot/1.0)'

    response = http.request(request)
    return nil unless response.code == '200'

    response.body
  rescue => e
    Rails.logger.warn("CouponScraper - fetch error #{url}: #{e.message}")
    nil
  end

  def extract_codes(html)
    codes = []

    # Extract from <code> tags
    html.scan(/<code[^>]*>([^<]+)<\/code>/i) do |match|
      code = match[0].strip
      codes << code if code.match?(COUPON_PATTERN) && code == code.upcase
    end

    # Extract codes near discount keywords in text
    segments = html.split(/\n/)
    segments.each do |line|
      next unless line.match?(DISCOUNT_KEYWORDS)

      line.scan(COUPON_PATTERN) do |code|
        codes << code if code.length >= 4
      end
    end

    codes.uniq.first(10)
  end
end
