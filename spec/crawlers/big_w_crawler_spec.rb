# frozen_string_literal: true
require 'rails_helper'

# The fixtures are trimmed copies of https://www.bigw.com.au/collection/deals
# (page 1 and ?page=2): a few product tiles plus the __NEXT_DATA__ listing. The
# real listing says pageCount 42, the fixtures say 2 to cover the stop condition.
RSpec.describe BigWCrawler do
  let(:crawler) { described_class.new }
  let(:deals_url) { 'https://www.bigw.com.au/collection/deals' }
  let(:html_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }
  let(:first_page) { File.read('spec/fixtures/big_w_crawler/deals_page_1.html') }
  let(:second_page) { File.read('spec/fixtures/big_w_crawler/deals_page_2.html') }

  before do
    allow(crawler).to receive(:sleep)
  end

  after do
    Faraday.default_connection = nil
  end

  describe '#crawl_all' do
    let!(:first_request) do
      stub_request(:get, deals_url)
        .to_return(status: 200, body: first_page, headers: html_headers)
    end
    let!(:second_request) do
      stub_request(:get, deals_url).with(query: { page: '2' })
        .to_return(status: 200, body: second_page, headers: html_headers)
    end

    it 'reads the products of every page from the embedded listing' do
      crawler.crawl_all

      expect(first_request).to have_been_requested.once
      expect(second_request).to have_been_requested.once
      expect(crawler.data.map { |product| product['id'] })
        .to eq %w[6001468 972303 52816 6054667 388993 9906040374]
      expect(crawler.data.first).to eq(
        'id' => '6001468',
        'name' => 'AIWA Smart Projector with Game Controllers',
        'price' => 74.0,
        'old_price' => 149.0,
        'image_url' => 'https://www.bigw.com.au/medias/sys_master/images/images/haf/h65/61665620951070.jpg',
        'store_path' => '/product/aiwa-smart-projector-with-game-controllers/p/6001468'
      )
    end

    it 'takes the previous price from wasPrice and leaves it empty when none is shown' do
      crawler.crawl_all

      clearance = crawler.data.find { |product| product['id'] == '972303' }
      expect(clearance).to include('price' => 23.0, 'old_price' => 39.95)

      multi_buy = crawler.data.find { |product| product['id'] == '52816' }
      expect(multi_buy).to include('price' => 57.0, 'old_price' => nil)
    end

    it 'sets no previous price for a product sold at a price range' do
      crawler.crawl_all

      # The tile shows "$37.49 - $49.99, SAVE $2.50" while savingsRange says 1246
      price_range = crawler.data.find { |product| product['id'] == '9906040374' }
      expect(price_range).to include('price' => 37.49, 'old_price' => nil)
    end

    it 'skips sponsored tiles' do
      crawler.crawl_all

      expect(crawler.data.map { |product| product['id'] }).not_to include('9900119953')
    end

    it 'stops at MAX_PAGES' do
      stub_const('BigWCrawler::MAX_PAGES', 1)

      crawler.crawl_all

      expect(second_request).not_to have_been_requested
      expect(crawler.data.size).to eq 3
    end

    context 'when a tile link is missing' do
      let(:first_page) do
        File.read('spec/fixtures/big_w_crawler/deals_page_1.html').gsub(/ data-product-code="[^"]+"/, '')
      end

      it 'builds the product path from the name and the code' do
        crawler.crawl_all

        expect(crawler.data.first['store_path'])
          .to eq '/product/aiwa-smart-projector-with-game-controllers/p/6001468'
      end
    end

    context 'when the listing has no pageCount' do
      let(:first_page) do
        File.read('spec/fixtures/big_w_crawler/deals_page_1.html').sub('"pageCount":2,', '')
      end

      it 'still reads the next page' do
        crawler.crawl_all

        expect(second_request).to have_been_requested.once
        expect(crawler.data.size).to eq 6
      end
    end

    context 'when a later page fails' do
      let!(:second_request) do
        stub_request(:get, deals_url).with(query: { page: '2' })
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'keeps the products of the previous pages' do
        crawler.crawl_all

        expect(crawler.data.size).to eq 3
      end
    end
  end

  describe '#crawl_all when the first page times out' do
    let!(:first_request) { stub_request(:get, deals_url).to_timeout }

    it do
      expect { crawler.crawl_all }.to raise_error(Faraday::Error)
      expect(first_request).to have_been_requested.twice
      expect(crawler.data).to be_empty
    end
  end

  describe '#crawl_all when the listing has moved' do
    before do
      stub_request(:get, deals_url)
        .to_return(status: 301, body: '', headers: { 'Location' => 'https://www.bigw.com.au/somewhere-else' })
    end

    it do
      expect { crawler.crawl_all }
        .to raise_error(RuntimeError, /BigWCrawler - no products on page 1 \(status 301, location "https:\/\/www.bigw.com.au\/somewhere-else"\)/)
      expect(crawler.data).to be_empty
    end
  end

  describe '#crawl_all when the page has no embedded listing' do
    before do
      stub_request(:get, deals_url)
        .to_return(status: 200, body: '<html><body><h1>Deals</h1></body></html>', headers: html_headers)
    end

    it do
      expect { crawler.crawl_all }
        .to raise_error(RuntimeError, /BigWCrawler - no products on page 1 \(status 200, location nil\)/)
      expect(crawler.data).to be_empty
    end
  end
end
