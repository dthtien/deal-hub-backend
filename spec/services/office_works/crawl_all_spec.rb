# frozen_string_literal: true
require 'spec_helper'

describe OfficeWorks::CrawlAll, :crawler do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::OFFICE_WORKS,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::OFFICE_WORKS,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        OfficeWorksCrawler,
        crawl_all: true,
        data: [
          {
            name: 'Product 1',
            price: 15_000,
            sku: product1.store_product_id,
            brand: 'brand',
            availState: ['NSW'],
            image: 'image.jpg',
            seoPath: 'seo-path',
            descriptionShort: 'description',
            categories: ['category']
          }.with_indifferent_access,
          {
            name: 'Product 2',
            price: 20_000,
            sku: '111111',
            brand: 'brand',
            availState: ['VIC'],
            image: 'image.jpg',
            seoPath: 'seo-path-2',
            descriptionShort: 'description',
            categories: ['category']
          }.with_indifferent_access
        ]
      )
    end

    before do
      allow(OfficeWorksCrawler).to receive(:new).and_return(crawler)
      service.call
    end

    it do
      product1.reload
      expect(Product.count).to eq 2
      expect(product1.price).to eq 150.0

      product = Product.where(store_product_id: '111111').first
      expect(product.price).to eq 200.0

      expect(Product.where(store_product_id: '654321').exists?).to be_falsey
    end
  end
end
