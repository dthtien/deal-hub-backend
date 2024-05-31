# frozen_string_literal: true

class JdSportsCrawler < ApplicationCrawler
  attr_reader :data

  def initialize
    super('https://www.jd-sports.com.au/')
    @data = []
    @categories = []
    @brands = []
  end

  def crawl_all
    fetch_page_details
    categories.each { |category| fetch_products_by_category(category) }

    self
  end

  private

  attr_reader :brands, :categories

  def fetch_data(path)
    response = client.get(path)
    Nokogiri::HTML(response.body)
  end

  def fetch_page_details
    document = fetch_data('sale/?AJAX=1')
    @categories = document.css('.filterSet.fhStyleStandard.fhSizeSml .list-filters .filterLink').map do |link|
      {
        name: link.css('span:first-child').text,
        path: link.attr('href')
      }
    end
    @brands = document.css('.filterSet.fhTypeMulti.fhSizeMed .list-filters .filterLink span:first-child').map do |span|
      span.text.downcase
    end
  end

  def fetch_products_by_category(category)
    document = fetch_data(category[:path])
    page_ids = document.css('#productListPagination a.pageLink').map { |a| a.attr('href') }
    page_ids.each do |page_id|
      response = client.get("#{page_id}&AJAX=1")
      @data += parse_items(response, category[:name])
    end
  end

  def parse_items(response, category)
    document = Nokogiri::HTML(response.body)
    document.css('#productListMain .productListItem').map do |product_element|
      parse_attributes(product_element).merge(categories: [category])
    end
  end

  def parse_attributes(element)
    price_element = element.css('.itemContainer .itemInformation .itemPrice')
    name = element.css('.itemContainer .itemInformation .itemTitle').text.strip
    {
      store_product_id: element.css('.itemContainer').attr('data-productsku').value,
      store_path: element.css('.itemContainer .itemImage').attr('href').value,
      image_url: parse_image_url(element),
      name:,
      old_price: price_element.css('.was span').text.strip.gsub('$', '').to_f,
      price: price_element.css('.now span').text.strip.gsub('$', '').to_f,
      brand: identify_brand(name)
    }
  end

  def parse_image_url(element)
    image_element = element.css('.itemContainer .itemImage .img-placeholder')
    url = image_element.attr('src').value
    return url if url.present? && !url.start_with?('/skins/default/')

    url = image_element.attr('data-src').value

    return url if url.present? && !url.start_with?('/skins/default/')

    url = image_element.attr('srcset').value.split(',').first.split(' ').first
    if url.present? && !url.start_with?('/skins/default/')
      url
    else
      "https://www.jd-sports.com.au#{url}"
    end
  end

  def identify_brand(name)
    brands.find { |brand| name.downcase.include?(brand) }.to_s.downcase.strip
  end
end
