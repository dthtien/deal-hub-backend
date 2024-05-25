# frozend_string_literal: true
require 'rails_helper'

RSpec.describe JdSports::CrawlAll do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::JD_SPORTS,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::JD_SPORTS,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        JdSportsCrawler,
        crawl_all: true,
        data: [
          {
            name: 'Product 1',
            price: 150,
            old_price: 200,
            store_product_id: product1.store_product_id,
            image_url: 'image.jpg',
            store_path: '/seo-path',
            categories: ['category']
          }.with_indifferent_access,
          {
            name: 'Product 2',
            price: 200,
            old_price: 250,
            store_product_id: '111111',
            image_url: 'image.jpg',
            store_path: 'seo-path-2',
            categories: ['category']
          }.with_indifferent_access,
          {
            name: 'Product bra 5',
            price: 200,
            old_price: 250,
            store_product_id: '1111119',
            image_url: 'image.jpg',
            store_path: 'seo-path-2',
            categories: ['category']
          }.with_indifferent_access

        ]
      )
    end

    before do
      allow(JdSportsCrawler).to receive(:new).and_return(crawler)
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
