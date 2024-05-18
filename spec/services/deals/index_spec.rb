require 'rails_helper'

RSpec.describe Deals::Index do
  let(:params) do
    {
      store: 'store',
      min_price: 10,
      max_price: 100,
      categories: %w[category category2],
      brand: 'brand',
      order: { price: :asc }
    }
  end
  let(:service) { described_class.new(params) }
  let!(:product1) { create(:product, price: 50, categories: ['category'], store: 'store', brand: 'brand') }
  let!(:product2) { create(:product, price: 20, categories: ['category2'], store: 'store2') }
  let!(:product3) { create(:product, price: 30, categories: ['category3'], store: 'store') }
  let!(:product4) { create(:product, price: 140, categories: ['category'], store: 'store') }
  let!(:product5) { create(:product, price: 99, categories: ['category'], store: 'store') }

  before { service.call }
  context '#call' do
    it do
      expect(service.products).to eq([product1])
    end
  end

  context '#paginate' do
    it do
      expect(service.paginate).to be_a(Pagination)
      expect(service.paginate.collection).to eq([product1])
      expect(service.paginate.metadata).to eq(
        page: 1,
        per_page: 25,
        total_count: 1,
        total_pages: 1
      )
    end
  end
end
