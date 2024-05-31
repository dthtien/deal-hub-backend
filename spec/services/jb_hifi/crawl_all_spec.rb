# frozend_string_literal: true
require 'rails_helper'

RSpec.describe JbHifi::CrawlAll do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::JB_HIFI,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::JB_HIFI,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        JbHifiCrawler,
        crawl_all: true,
        data: [
          {
            title: 'Product 1',
            pricing: { displayPriceInc: 150, wasPrice: 200 },
            sku: product1.store_product_id,
            product: { brand: 'brand' },
            product_image: 'image.jpg',
            handle: 'seo-path',
            display: { keyFeatures: ['description'] },
            category_hierarchy: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 2',
            pricing: { displayPriceInc: 200 },
            sku: '111111',
            product: { brand: 'brand' },
            product_image: 'image.jpg',
            handle: 'seo-path-2',
            display: { keyFeatures: ['description'] },
            category_hierarchy: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 3',
            pricing: { displayPriceInc: 200 },
            sku: '',
            product: { brand: 'brand', id: '111112' },
            product_image: 'image.jpg',
            handle: 'seo-path-3',
            display: { keyFeatures: ['description'] },
            category_hierarchy: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 4',
            pricing: { displayPriceInc: 200 },
            sku: '',
            product: { brand: 'brand', id: '111113' },
            product_image: 'image.jpg',
            handle: 'seo-path-3',
            display: { keyFeatures: ['description'] },
            category_hierarchy: ['merchandise']
          }.with_indifferent_access,
          {
            title: 'Product 5',
            pricing: { displayPriceInc: 200 },
            sku: '1111115',
            product: { brand: 'brand' },
            product_image: 'image.jpg',
            handle: 'seo-path-3',
            display: { keyFeatures: ['description'] },
            category_hierarchy: ['figurines']
          }.with_indifferent_access

        ]
      )
    end

    before do
      allow(JbHifiCrawler).to receive(:new).and_return(crawler)
      service.call
    end

    it do
      product1.reload
      expect(Product.count).to eq 3
      expect(product1.price).to eq 150.0
      expect(product1.old_price).to eq 200.0
      expect(product1.discount).to eq 25.0

      product = Product.find_by(store_product_id: '111111')
      expect(product.price).to eq 200.0

      product = Product.find_by(store_product_id: '111112')
      expect(product.price).to eq 200.0

      expect(Product.where(store_product_id: '654321').exists?).to be_falsey
    end
  end
end
