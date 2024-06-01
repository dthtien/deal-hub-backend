# frozen_string_literal: true
require 'rails_helper'

describe Asos::CrawlAll, :crawler do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::ASOS,
        store_product_id: '123456',
        price: 100
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::ASOS,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        AsosCrawler,
        crawl_all: true,
        data: [
          {
            name: 'Product 1',
            price: { current: { value: 150 }, previous: { value: 200 } },
            id: product1.store_product_id,
            brandName: 'brand',
            imageUrl: 'image.jpg',
            url: 'seo-path'
          }.with_indifferent_access,
          {
            name: 'Product 2',
            price: { current: { value: 200 }, previous: { value: 250 } },
            id: '111111',
            brandName: 'brand',
            imageUrl: 'image.jpg',
            url: 'seo-path-2',
          }.with_indifferent_access,
          {
            name: 'Product bikini',
            price: { current: { value: 200 }, previous: { value: 250 } },
            id: '1111112',
            brandName: 'brand',
            imageUrl: 'image.jpg',
            url: 'seo-path-3',
          }.with_indifferent_access,
          {
            name: 'Product 5 bodysuit',
            price: { current: { value: 200 }, previous: { value: 250 } },
            id: '1111112',
            brandName: 'brand',
            imageUrl: 'image.jpg',
            url: 'seo-path-4',
          }.with_indifferent_access
        ]
      )
    end

    before do
      allow(AsosCrawler).to receive(:new).and_return(crawler)
      service.call
    end

    it do
      product1.reload
      expect(Product.count).to eq 2
      expect(product1.price).to eq 150.0
      expect(product1.discount).to eq 25.0

      product = Product.where(store_product_id: '111111').first
      expect(product.price).to eq 200.0

      expect(Product.where(store_product_id: '654321').exists?).to be_falsey
    end
  end
end


