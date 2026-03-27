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
            'id' => product1.store_product_id.to_i,
            'title' => 'Product 1',
            'vendor' => 'brand',
            'handle' => 'seo-path',
            'tags' => ['category', 'sub-category'],
            'images' => [{ 'src' => 'https://example.com/image.jpg' }],
            'variants' => [{ 'price' => '150.0', 'compare_at_price' => '200.0' }]
          },
          {
            'id' => 111_111,
            'title' => 'Product 2',
            'vendor' => 'brand',
            'handle' => 'seo-path-2',
            'tags' => ['category'],
            'images' => [{ 'src' => 'https://example.com/image.jpg' }],
            'variants' => [{ 'price' => '200.0', 'compare_at_price' => '250.0' }]
          },
          {
            'id' => 1_111_112,
            'title' => 'Product bikini',
            'vendor' => 'brand',
            'handle' => 'seo-path-3',
            'tags' => ['category'],
            'images' => [{ 'src' => 'https://example.com/image.jpg' }],
            'variants' => [{ 'price' => '200.0', 'compare_at_price' => '250.0' }]
          },
          {
            'id' => 1_111_113,
            'title' => 'Product 5 bodysuit',
            'vendor' => 'brand',
            'handle' => 'seo-path-4',
            'tags' => ['category'],
            'images' => [{ 'src' => 'https://example.com/image.jpg' }],
            'variants' => [{ 'price' => '200.0', 'compare_at_price' => '400.0' }]
          }
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
