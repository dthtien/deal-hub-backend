# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TheGoodGuysCrawler do
  describe '#crawl_all' do
    let(:crawler) { described_class.new }

    before do
      stub_request(:get, TheGoodGuysCrawler::SALE_IDS_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/the_good_guys_crawler/ids.json'))
      stub_request(:post, TheGoodGuysCrawler::SALE_DEALS_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/the_good_guys_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 4
      expect(crawler.data.first).to include(*%w[name fields])
    end
  end
end
