require 'spec_helper'

describe OfficeWorksCrawler, :crawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:post, %r{\Ahttps://k535caawve-dsn.algolia.net/1/indexes/\*/queries})
        .to_return(status: 200, body: File.read('spec/fixtures/office_works_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 22
      expect(crawler.data.first).to include('objectID', 'name', 'price', 'sku')
    end
  end

  describe '#crawl_price' do
    before do
      stub_request(:get, 'https://www.officeworks.com.au/catalogue-app/api/prices/123456')
        .to_return(status: 200, body: '{"price": 123.45}')
    end

    it do
      expect(crawler.crawl_price('123456')).to eq('price' => 123.45)
    end
  end
end
