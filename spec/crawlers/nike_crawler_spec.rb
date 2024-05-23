# frozen_string_literal: true
require 'rails_helper'

RSpec.describe NikeCrawler do
  describe '#crawl_all' do
    let(:crawler) { described_class.new }
    after do
      Faraday.default_connection = nil
    end

    before do
      stub_request(:get, %r{\Ahttps://api.nike.com/cic/browse/v2})
        .to_return(status: 200, body: File.read('spec/fixtures/nike_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 24
      expect(crawler.data.first).to include('title', 'url', 'id')
    end
  end
end
