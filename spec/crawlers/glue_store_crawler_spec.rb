#frozen_string_literal: true
require 'rails_helper'

RSpec.describe GlueStoreCrawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:post, %r{\Ahttps://aw7pfg4ytn-dsn.algolia.net/1/indexes/\*/queries})
        .to_return(status: 200, body: File.read('spec/fixtures/glue_store_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 20
      expect(crawler.data.first).to include('title', 'price', 'sku')
    end
  end
end
