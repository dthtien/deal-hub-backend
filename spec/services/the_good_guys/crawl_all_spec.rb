# frozend_string_literal: true
require 'rails_helper'

RSpec.describe TheGoodGuys::CrawlAll do
  let(:service) { described_class.new }

  describe '#call' do
    let!(:product1) do
      create(
        :product,
        name: 'New product',
        store: Product::THE_GOOD_GUYS,
        store_product_id: '123456',
        price: 10_000
      )
    end
    let!(:product2) do
      create(
        :product,
        name: 'Old product',
        store: Product::THE_GOOD_GUYS,
        store_product_id: '654321'
      )
    end
    let(:crawler) do
      instance_double(
        TheGoodGuysCrawler,
        crawl_all: true,
        data: [
          build_data(
            'Product 1',
            product1.store_product_id,
            '150',
            '200',
            'brand',
            'image.jpg',
            'seo-path',
            'category'
          ),
          build_data(
            'Product 2',
            '111111',
            '200',
            '250',
            'brand',
            'image.jpg',
            'seo-path-2',
            'category'
          ),
          build_data(
            'Product 3',
            '111112',
            '200',
            '250',
            'brand',
            'image.jpg',
            'seo-path-3',
            'category'
          )
        ]
      )
    end

    before do
      allow(TheGoodGuysCrawler).to receive(:new).and_return(crawler)
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

  def build_data(title, sku, price, old_price, brand, image, handle, category)
    {
      fields: {
        'longDescription': { "stringValue": ''},
        'inStockFlag': {
          'stringValue': 'Y'
        },
        "images": {
          "arrayValue": {
            "values": [
              {
                "mapValue": {
                  "fields": {
                    "Url": {
                      "stringValue": image
                    },
                    "Seq": {}
                  }
                }
              }
            ]
          }
        },
        "wasPrice": { "stringValue": old_price },
        "heading": {
          "stringValue": title
        },
        "shortDescription": { "stringValue": 'description' },
        "price": { "stringValue": price },
        "categories": {
          "mapValue": {
            "fields": {
              "l1": {
                "mapValue": {
                  "fields": {
                    "name": {
                      "stringValue": category
                    }
                  }
                }
              }
            }
          }
        },
        "sku": { "stringValue": sku },
        "productUrl": { "stringValue": handle },
        "brand": {
          "mapValue": {
            "fields": {
              "name": { "stringValue": brand }
            }
          }
        }
      }
    }.with_indifferent_access
  end
end
