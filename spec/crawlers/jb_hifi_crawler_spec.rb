#frozen_string_literal: true
require 'rails_helper'

RSpec.describe JbHifiCrawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:post, %r{\Ahttps://vtvkm5urpx-dsn.algolia.net/1/indexes/\*/queries})
        .to_return(status: 200, body: File.read('spec/fixtures/jb_hifi_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 36
      expect(crawler.data.first).to include('title', 'pricing', 'sku')
    end
  end
end
