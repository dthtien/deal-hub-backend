# frozen_string_literal: true

class TheIconicCrawler < ApplicationCrawler
  attr_reader :data
  MAX_ITEM_COUNT = 1000
  ITEM_PER_PAGE = 48

  def initialize
    super('https://www.theiconic.com.au/')
    @data = []
    @categories = [
      {
        name: 'shoes',
        path: 'shoes-sale'
      },
      {
        name: 'clothing',
        path: 'clothing-sale'
      }
    ]
  end

  def crawl_all
    categories.each { |category| fetch_products_by_category(category) }

    self
  end

  private

  attr_reader :brands, :categories

  def fetch_data(path)
    response = client.get(path, request_params)
    Nokogiri::HTML(response.body)
  end

  def fetch_products_by_category(category)
    document = fetch_data(category[:path])
    item_counts = document.css('.items-count').text.to_i
    item_counts = MAX_ITEM_COUNT if item_counts > MAX_ITEM_COUNT
    total_pages = (item_counts.to_f / ITEM_PER_PAGE).ceil
    current_page = 1

    while current_page <= total_pages
      response = client.get(category[:path], request_params.merge(page: current_page))
      @data += parse_items(response, category[:name])

      current_page += 1
    end
  end

  def request_params
    {
      sort: 'popularity',
      special_price: 1
    }
  end

  def parse_items(response, category)
    document = Nokogiri::HTML(response.body)
    document.css('.product').map do |product_element|
      parse_attributes(product_element).merge(categories: [category])
    end
  end

  def parse_attributes(element)
    {
      store_product_id: element.attr('data-ti-track-product'),
      store_path: element.css('.product-image-link').attr('href').value,
      image_url: parse_image_url(element),
      name: element.css('.name').text.strip,
      old_price: element.css('.price.original').text.strip.gsub('$', '').to_f,
      price: parse_price(element),
      brand: element.css('.brand').text.strip
    }
  end

  def parse_price(element)
    price = element.css('.price.final').text.strip.gsub('$', '').to_f
    return price if price.positive?

    element.css('.price').text.strip.gsub('$', '').to_f
  end

  def parse_old_price(element)
    price = element.css('.price.original').text.strip.gsub('$', '').to_f

    price.positive? ? price : nil
  end

  def parse_image_url(element)
    first_image = element.css('.product-image-link img').first
    url = first_image.attr('src') || first_image.attr('data-src')
    return url if url.blank? || url.start_with?('data:image') || url.start_with?('http')

    "https:#{url}"
  end
end
