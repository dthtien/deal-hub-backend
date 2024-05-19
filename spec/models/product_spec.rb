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
      expect(product.as_json).to match(
        product.attributes.merge(
          store_url: nil,
          'updated_at' => product.updated_at.strftime(::Product::DATE_FORMAT),
          'created_at' => product.created_at.strftime(::Product::DATE_FORMAT)
        )
      )
    end
  end
end
