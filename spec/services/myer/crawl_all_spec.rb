# frozend_string_literal: true
require 'rails_helper'

RSpec.describe Myer::CrawlAll do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::MYER,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::MYER,
        store_product_id: '654321'
      )
    end
    let(:data) do
      [
        {
          name: 'Product 1',
          priceFrom: 150,
          listPriceFrom: 200,
          id: product1.store_product_id,
          media: [{ 'baseUrl' => 'image.jpg' }],
          seoToken: '/seo-path',
          merchCategory: 'category'
        }.with_indifferent_access,
        {
          name: 'Product 2',
          priceFrom: 200,
          listPriceFrom: 250,
          id: '111111',
          media: [{ 'baseUrl' => 'image.jpg' }],
          seoToken: 'seo-path-2',
          merchCategory: 'category'
        }.with_indifferent_access,
        {
          name: 'Product bra 5',
          priceFrom: 200,
          listPriceFrom: 250,
          id: '1111119',
          media: [{ 'baseUrl' => 'image.jpg' }],
          seoToken: 'seo-path-3',
          merchCategory: 'category'
        }.with_indifferent_access
      ]
    end
    let(:crawler) do
      instance_double(MyerCrawler)
    end

    before do
      allow(MyerCrawler).to receive(:new).and_return(crawler)
      expect(crawler).to receive(:crawl_all).and_yield(data)
      service.call
    end

    it do
      product1.reload
      expect(Product.count).to eq 2
      expect(product1.price).to eq 150.0

      product = Product.find_by(store_product_id: '111111')
      expect(product.price).to eq 200.0

      expect(Product.where(store_product_id: %w[654321 1111119]).exists?).to be_falsey
    end
  end
end

