# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Product, :model, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:store_product_id) }
    it { is_expected.to validate_presence_of(:store) }
  end

  describe '#as_json' do
    let(:product) { create(:product) }

    it do
      expected = product.attributes.merge(
        'deal_score' => 0,
        'discount' => 0.0,
        'old_price' => 0.0,
        'price' => product.price.to_f,
        'updated_at' => product.updated_at.strftime(::Product::DATE_FORMAT),
        'created_at' => product.created_at.strftime(::Product::DATE_FORMAT),
        'commission_rate' => a_kind_of(Numeric).or(a_kind_of(String))
      ).merge(
        store_url: nil,
        click_count: 0,
        deal_score: 0,
        freshness_score: an_instance_of(Integer),
        recency_score: an_instance_of(Integer),
        quality_score: an_instance_of(Integer),
        heat_index: 0,
        aggregate_score: an_instance_of(Float),
        affiliate_network: an_instance_of(String),
        best_deal: false,
        price_trend: :stable,
        is_bundle: false,
        bundle_quantity: an_instance_of(Integer),
        price_per_unit: nil,
        in_stock: true,
        ai_recommendation: nil,
        ai_confidence: nil,
        ai_reasoning_short: nil,
        tags: [],
        image_urls: [],
        price_prediction: nil,
        share_count: 0,
        view_count: 0,
        avg_rating: 0.0,
        rating_count: 0,
        popularity_score: an_instance_of(Float),
        community_score: an_instance_of(Float),
        status: an_instance_of(String),
        going_fast: false,
        discount_tier: nil,
        shipping_info: anything,
        optimized_image_url: anything,
        trending_velocity: an_instance_of(Float)
      )
      expect(product.as_json).to match(expected)
    end
  end

  describe '.brands' do
    let!(:product1) { create(:product, brand: 'brand1') }
    let!(:product2) { create(:product, brand: 'brand2') }
    let!(:product3) { create(:product, brand: 'brand1') }

    it do
      expect(described_class.brands).to match_array(%w[brand1 brand2])
    end
  end

  describe '.categories' do
    let!(:product1) { create(:product, categories: ['category1']) }
    let!(:product2) { create(:product, categories: ['category2']) }
    let!(:product3) { create(:product, categories: ['category1']) }

    it do
      expect(described_class.categories).to match_array(%w[category1 category2])
    end
  end

  describe '.stores' do
    let!(:product1) { create(:product, store: 'store1') }
    let!(:product2) { create(:product, store: 'store2') }
    let!(:product3) { create(:product, store: 'store1') }

    it do
      expect(described_class.stores).to match_array(%w[store1 store2])
    end
  end
end
