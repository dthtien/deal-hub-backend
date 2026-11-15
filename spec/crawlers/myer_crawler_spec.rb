#frozen_string_literal: true
require 'rails_helper'

RSpec.describe MyerCrawler do
  let(:crawler) { described_class.new }
  let(:listing_url) { 'https://www.myer.com.au/c/offers/sale-all' }

  after do
    Faraday.default_connection = nil
  end

  # A listing page shaped like the real one: the products sit in the __NEXT_DATA__ script
  def listing_html(ids:, total:)
    listing = {
      productTotalCount: total,
      productsPerPage: 48,
      productList: ids.map { |id| { id: id.to_s, name: "Product #{id}", brand: 'Brand' } }
    }
    queries = [
      { queryKey: ['toggles'], state: { data: {} } },
      { queryKey: ['category', '/offers/sale-all', 1, [], 'relevance'], state: { data: listing } }
    ]
    next_data = { props: { pageProps: { dehydratedState: { queries: } } } }
    %(<html><body><script id="__NEXT_DATA__" type="application/json">#{next_data.to_json}</script></body></html>)
  end

  describe '#crawl_all' do
    before do
      # trimmed copy of https://www.myer.com.au/c/offers/sale-all (3 products, count adjusted)
      stub_request(:get, listing_url)
        .to_return(status: 200, body: File.read('spec/fixtures/myer_crawler/sale_all.html'))

      crawler.crawl_all
    end

    it do
      expect(crawler.data.size).to eq 3
      expect(crawler.data.first).to include(*%w[id name brand])
      expect(crawler.data.first).to include(
        'id' => '749269990_749267470',
        'brand' => 'Australian House & Garden',
        'priceFrom' => 10,
        'listPriceFrom' => 20,
        'seoToken' => 'australian-house-garden-australian-cotton-towel-range-in-charcoal'
      )
      expect(a_request(:get, listing_url)).to have_been_made.once
    end
  end

  describe '#crawl_all with several pages' do
    before do
      allow(crawler).to receive(:sleep)
      stub_request(:get, listing_url)
        .to_return(status: 200, body: listing_html(ids: 1..48, total: 100))
      stub_request(:get, listing_url).with(query: { 'pageNumber' => '2' })
        .to_return(status: 200, body: listing_html(ids: 49..96, total: 100))
      stub_request(:get, listing_url).with(query: { 'pageNumber' => '3' })
        .to_return(status: 200, body: listing_html(ids: 97..100, total: 100))
    end

    it 'follows ?pageNumber=N up to the last page' do
      yielded = []
      crawler.crawl_all { |results| yielded << results.size }

      expect(yielded).to eq [48, 48, 4]
      expect(crawler.data.size).to eq 100
      expect(a_request(:get, %r{\Ahttps://www.myer.com.au/c/offers/sale-all})).to have_been_made.times(3)
      expect(crawler).to have_received(:sleep).twice
    end
  end

  describe '#crawl_all when the first page has no productTotalCount' do
    before do
      stub_request(:get, listing_url)
        .to_return(status: 403, body: '<html><body>Access Denied</body></html>')
    end

    it do
      expect { crawler.crawl_all }
        .to raise_error(RuntimeError, /MyerCrawler - first page has no productTotalCount \(status 403\)/)
      expect(crawler.data).to be_empty
    end
  end

  describe '#crawl_all when a later page is refused' do
    before do
      allow(crawler).to receive(:sleep)
      allow(Rails.logger).to receive(:error)
      stub_request(:get, listing_url)
        .to_return(status: 200, body: listing_html(ids: 1..48, total: 100))
      stub_request(:get, listing_url).with(query: { 'pageNumber' => '2' })
        .to_return(status: 429, body: '<html><body>Too Many Requests</body></html>')
    end

    it 'stops without asking for more pages, keeps what it has and logs why' do
      crawler.crawl_all

      expect(crawler.data.size).to eq 48
      expect(a_request(:get, %r{\Ahttps://www.myer.com.au/c/offers/sale-all})).to have_been_made.times(2)
      expect(Rails.logger).to have_received(:error)
        .with(/MyerCrawler - page 2 returned no products \(status 429\), stopping with 48 products collected/)
    end
  end

  describe '#crawl_all when every attempt fails on the network' do
    before do
      stub_request(:get, listing_url).to_timeout
    end

    it 'retries, then reports the missing first page (no NameError from the fallback response)' do
      expect { crawler.crawl_all }
        .to raise_error(RuntimeError, /MyerCrawler - first page has no productTotalCount \(status nil\)/)
      expect(a_request(:get, listing_url)).to have_been_made.times(4)
      expect(crawler.data).to be_empty
    end
  end
end
