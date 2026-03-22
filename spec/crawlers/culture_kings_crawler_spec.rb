# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CultureKingsCrawler do
  let(:crawler) { described_class.new }

  describe '#crawl_all' do
    before do
      stub_request(:get, %r{\Ahttps://www\.culturekings\.com\.au/collections/all-sale/products\.json})
        .to_return(status: 200, body: File.read('spec/fixtures/culture_kings_crawler/shopify_page.json'),
                   headers: { 'Content-Type' => 'application/json' })

      crawler.crawl_all
    end

    it 'returns products with expected fields' do
      expect(crawler.data).not_to be_empty
      expect(crawler.data.first).to include('id', 'name', 'price')
    end
  end
end
