#frozen_string_literal: true
require 'rails_helper'

RSpec.describe TheIconicCrawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:get, %r{\Ahttps://www.theiconic.com.au/shoes-sale})
        .to_return(status: 200, body: File.read('spec/fixtures/the_iconic_crawler/shoes.html'))
      stub_request(:get, %r{\Ahttps://www.theiconic.com.au/clothing-sale})
        .to_return(status: 200, body: File.read('spec/fixtures/the_iconic_crawler/clothing.html'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 96
      expect(crawler.data.first).to include(
        :name,
        :price,
        :store_product_id,
        :brand,
        :image_url,
        :store_path,
        :categories
      )
    end
  end
end
