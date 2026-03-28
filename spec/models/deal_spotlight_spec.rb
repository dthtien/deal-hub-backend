# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DealSpotlight, type: :model do
  let(:product) do
    Product.create!(
      name: 'Test Product', price: 99.0, store: 'JB Hi-Fi',
      store_product_id: "sp-#{SecureRandom.hex(4)}"
    )
  end

  describe 'validations' do
    it 'is valid with title and product' do
      s = DealSpotlight.new(title: 'Hot Deal', product: product, position: 0)
      expect(s).to be_valid
    end

    it 'requires title' do
      s = DealSpotlight.new(product: product, position: 0)
      expect(s).not_to be_valid
    end
  end

  describe '.active_now' do
    it 'includes active spotlights with no expiry' do
      s = DealSpotlight.create!(title: 'T', product: product, active: true, position: 0)
      expect(DealSpotlight.active_now).to include(s)
    end

    it 'excludes expired spotlights' do
      s = DealSpotlight.create!(title: 'T', product: product, active: true, position: 0, featured_until: 1.day.ago)
      expect(DealSpotlight.active_now).not_to include(s)
    end

    it 'excludes inactive spotlights' do
      s = DealSpotlight.create!(title: 'T', product: product, active: false, position: 0)
      expect(DealSpotlight.active_now).not_to include(s)
    end
  end
end
