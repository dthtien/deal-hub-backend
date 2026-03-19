# frozen_string_literal: true

class BookingComCrawler < ApplicationCrawler
  BASE_URL = 'https://www.booking.com'
  SEARCH_PATH = '/searchresults.html'

  # Australian cities with Booking.com dest_ids
  DESTINATIONS = [
    { name: 'sydney', dest_id: '-1603135', dest_type: 'city' },
    { name: 'melbourne', dest_id: '-1603220', dest_type: 'city' },
    { name: 'brisbane', dest_id: '-1603024', dest_type: 'city' },
    { name: 'perth', dest_id: '-1603404', dest_type: 'city' }
  ].freeze

  attr_reader :data

  def initialize
    super(BASE_URL)
    @data = []
  end

  def crawl_all
    DESTINATIONS.each do |dest|
      results = parse(fetch_list(dest))
      @data += results
    end

    @data = @data.uniq { |p| p['id'] }
    self
  end

  private

  def fetch_list(destination)
    checkin = (Date.today + 1).strftime('%Y-%m-%d')
    checkout = (Date.today + 4).strftime('%Y-%m-%d')

    client.get(SEARCH_PATH, params(destination, checkin, checkout)) do |req|
      req.headers['Accept'] = 'text/html,application/xhtml+xml'
      req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      req.headers['Accept-Language'] = 'en-AU,en;q=0.9'
    end
  end

  def parse(response)
    doc = Nokogiri::HTML(response.body)
    properties = []

    # Booking.com property cards
    doc.css('[data-testid="property-card"], .sr_item, [class*="PropertyCard"]').each do |card|
      property = extract_property(card)
      properties << property if property
    end

    properties
  rescue => e
    Rails.logger.error "BookingComCrawler parse error: #{e.message}"
    []
  end

  def extract_property(card)
    name_el = card.at_css('[data-testid="title"], .sr-hotel__name, [class*="PropertyName"], h3')
    price_el = card.at_css('[data-testid="price-and-discounted-price"], .bui-price-display__value, [class*="Price"]')
    location_el = card.at_css('[data-testid="address"], .sr_card_address_line, [class*="Address"]')
    image_el = card.at_css('img[data-testid="image"], img.sr_card_photo_img, img')
    link_el = card.at_css('a[data-testid="title-link"], a.hotel_name_link, a')
    score_el = card.at_css('[data-testid="review-score"], .bui-review-score__badge')

    name = name_el&.text&.strip
    return nil if name.blank?

    price_text = price_el&.text&.strip&.gsub(/[^0-9.]/, '')
    price = price_text.to_f
    return nil if price.zero?

    link = link_el&.[]('href')
    full_url = link&.start_with?('http') ? link : "#{BASE_URL}#{link}"
    property_id = link&.match(/\/hotel\/([\w-]+)/)&.[](1) || name.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '')

    {
      'id' => property_id,
      'name' => name,
      'price' => price,
      'old_price' => 0,
      'location' => location_el&.text&.strip,
      'image_url' => image_el&.[]('src') || image_el&.[]('data-src'),
      'store_path' => full_url,
      'score' => score_el&.text&.strip
    }
  end

  def params(destination, checkin, checkout)
    {
      dest_id: destination[:dest_id],
      dest_type: destination[:dest_type],
      checkin:,
      checkout:,
      group_adults: 2,
      currency: 'AUD',
      selected_currency: 'AUD',
      nflt: 'price%3DAUD-min-150-1',
      order: 'price'
    }
  end
end
