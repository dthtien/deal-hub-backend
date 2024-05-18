require 'rails_helper'

RSpec.describe Pagination do
  let!(:product1) { create(:product, price: 50, categories: ['category'], store: 'store') }
  let!(:product2) { create(:product, price: 20, categories: ['category2'], store: 'store2') }
  let!(:product3) { create(:product, price: 30, categories: ['category3'], store: 'store') }

  let(:collection) { Product.all }

  let(:params) do
    {
      page: 1,
      per_page: 1
    }
  end

  let(:pagination) { described_class.new(collection, params) }

  before { pagination.call }

  context '#call' do
    it do
      expect(pagination.collection).to eq([product1])
      expect(pagination.metadata).to eq(
        page: 1,
        per_page: 1,
        total_count: 3,
        total_pages: 3
      )
    end
  end
end
