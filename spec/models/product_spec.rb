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

    it 'returns the product as a hash' do
      expect(product.as_json).to eq(
        product.attributes.except('created_at').merge(
          store_url: nil,
          'updated_at' => product.updated_at.iso8601(3)
        )
      )
    end
  end
end
