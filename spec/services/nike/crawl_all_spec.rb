# frozend_string_literal: true
require 'rails_helper'

RSpec.describe Nike::CrawlAll do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::NIKE,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::NIKE,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        NikeCrawler,
        crawl_all: true,
        data: [
          {
            title: 'Product 1',
            price: { currentPrice: 150 },
            id: product1.store_product_id,
            images: { portraitURL: 'image.jpg' },
            url: '{countryLang}/seo-path',
            subtitle: 'description',
            productType: 'category'
          }.with_indifferent_access,
          {
            title: 'Product 2',
            price: { currentPrice: 200 },
            id: '111111',
            images: { portraitURL: 'image.jpg' },
            url: 'seo-path-2',
            subtitle: 'description',
            productType: 'category'
          }.with_indifferent_access,
          {
            title: 'Product bra 5',
            price: { currentPrice: 200 },
            id: '1111119',
            images: { portraitURL: 'image.jpg' },
            url: 'seo-path-2',
            subtitle: 'description',
            productType: 'category'
          }.with_indifferent_access

        ]
      )
    end

    before do
      allow(NikeCrawler).to receive(:new).and_return(crawler)
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

