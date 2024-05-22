# frozen_string_literal: true
require 'rails_helper'

describe GlueStore::CrawlAll, :crawler do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::GLUE_STORE,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::GLUE_STORE,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        GlueStoreCrawler,
        crawl_all: true,
        data: [
          {
            title: 'Product 1',
            price: 150,
            sku: product1.store_product_id,
            vendor: 'brand',
            product_image: 'image.jpg',
            handle: 'seo-path',
            body_html_safe: 'description',
            tags: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 2',
            price: 200,
            sku: '111111',
            vendor: 'brand',
            product_image: 'image.jpg',
            handle: 'seo-path-2',
            body_html_safe: 'description',
            tags: ['category']
          }.with_indifferent_access,
          {
            title: 'Product bikini',
            price: 200,
            sku: '1111112',
            vendor: 'brand',
            product_image: 'image.jpg',
            handle: 'seo-path-3',
            body_html_safe: 'description',
            tags: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 5',
            price: 200,
            sku: '1111112',
            vendor: 'brand',
            product_image: 'image.jpg',
            handle: 'seo-path-3',
            body_html_safe: 'description',
            tags: ['Swimwear']
          }.with_indifferent_access
        ]
      )
    end

    before do
      allow(GlueStoreCrawler).to receive(:new).and_return(crawler)
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

