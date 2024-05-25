#frozen_string_literal: true
require 'rails_helper'

RSpec.describe JdSportsCrawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:get, %r{\Ahttps://www.jd-sports.com.au/sale})
        .to_return(status: 200, body: File.read('spec/fixtures/jd_sports_crawler/sale.html'))
      stub_request(:get, %r{\Ahttps://www.jd-sports.com.au/men/sale})
        .to_return(status: 200, body: File.read('spec/fixtures/jd_sports_crawler/sale.html'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 72
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

