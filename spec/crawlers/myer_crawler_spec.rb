#frozen_string_literal: true
require 'rails_helper'

RSpec.describe MyerCrawler do
  let(:crawler) { described_class.new }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:get, %r{\Ahttps://api-online.myer.com.au/v3/product})
        .to_return(status: 200, body: File.read('spec/fixtures/myer_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 48
      expect(crawler.data.first).to include(*%w[id name brand])
    end
  end
end
