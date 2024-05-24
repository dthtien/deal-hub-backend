# frozen_string_literal: true
require 'rails_helper'

describe CultureKings::CrawlAll, :crawler do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::CULTURE_KINGS,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::CULTURE_KINGS,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        CultureKingsCrawler,
        crawl_all: true,
        data: [
          {
            title: 'Product 1',
            price: 150,
            compareAtPrice: 200,
            productId: product1.store_product_id,
            vendor: 'brand',
            image: 'image.jpg',
            handle: 'seo-path',
            description: 'description',
            categoriesNormalised: ['category', 'sub-category']
          }.with_indifferent_access,
          {
            title: 'Product 2',
            price: 200,
            compareAtPrice: 250,
            productId: '111111',
            vendor: 'brand',
            image: 'image.jpg',
            handle: 'seo-path-2',
            description: 'description',
            categoriesNormalised: ['category']
          }.with_indifferent_access,
          {
            title: 'Product bikini',
            price: 200,
            compareAtPrice: 250,
            productId: '1111112',
            vendor: 'brand',
            image: 'image.jpg',
            handle: 'seo-path-3',
            description: 'description',
            categoriesNormalised: ['category']
          }.with_indifferent_access,
          {
            title: 'Product 5 bodysuit',
            price: 200,
            compareAtPrice: 400,
            productId: '1111112',
            vendor: 'brand',
            image: 'image.jpg',
            handle: 'seo-path-4',
            description: 'description'
          }.with_indifferent_access
        ]
      )
    end

    before do
      allow(CultureKingsCrawler).to receive(:new).and_return(crawler)
      service.call
    end

    it do
      product1.reload
      expect(Product.count).to eq 2
      expect(product1.price).to eq 150.0
      expect(product1.discount).to eq 25.0
      expect(product1.categories).to eq %w[category sub-category]

      product = Product.where(store_product_id: '111111').first
      expect(product.price).to eq 200.0

      expect(Product.where(store_product_id: '654321').exists?).to be_falsey
    end
  end
end

