#frozen_string_literal: true
require 'rails_helper'

RSpec.describe AsosCrawler do
  let(:url) { 'https://www.asos.com/api/product/search/v2/categories' }
  let(:crawler) { described_class.new(url) }

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    before do
      stub_request(:get, /\A#{url}/)
        .to_return(status: 200, body: File.read('spec/fixtures/asos_crawler/first_page.json'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 72
      expect(crawler.data.first).to include(*%w[id name brandName price])
    end
  end
end
