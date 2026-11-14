require 'rails_helper'

RSpec.describe Deals::Index do
  let(:params) do
    {
      stores: { '0' => 'store' },
      min_price: 10,
      max_price: 100,
      categories: { '0' => 'category', '1' => 'category2' },
      brands: { '0' => 'brand' },
      name: 'product',
      order: { price: :asc }
    }
  end
  let(:service) { described_class.new(params) }
  let!(:product1) do
    create(
      :product,
      price: 50,
      categories: ['category'],
      store: 'store',
      brand: 'brand',
      name: 'product'
    )
  end
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

  context 'with ActionController::Parameters (indexed arrays from the frontend, e.g. stores[0]=...)' do
    let(:params) do
      ActionController::Parameters.new(
        'stores' => { '0' => 'store' },
        'categories' => { '0' => 'category', '1' => 'category2' },
        'brands' => { '0' => 'brand' },
        'min_price' => '10',
        'max_price' => '100'
      )
    end

    it 'filters without raising a cast error' do
      expect(service.products).to eq([product1])
    end
  end

  context 'with a search query' do
    let(:params) { { query: query } }
    let!(:vacuum) { create(:product, name: 'Handheld Stick Vacuum') }
    let(:results) { described_class.new(params).call.products.to_a }

    before do
      Product.where(id: vacuum.id).update_all("search_vector = to_tsvector('english', name)")
    end

    context 'with a single word' do
      let(:query) { 'handheld' }

      it 'does not raise a tsquery syntax error' do
        expect(results).to eq([vacuum])
      end
    end

    context 'with several word prefixes in any order' do
      let(:query) { 'vac hand' }

      it 'matches through the search vector' do
        expect(results).to eq([vacuum])
      end
    end

    context 'with quotes, backslashes and tsquery operators' do
      let(:query) { "hand' & (vac | !stick):* \\ <->" }

      it 'treats them as plain text' do
        expect(results).to eq([vacuum])
      end
    end

    context 'without ordering, as the metadata endpoint calls it' do
      let(:query) { 'handheld' }

      it 'allows the DISTINCT plucks' do
        unordered = described_class.new(params, with_order: false).call
        expect(unordered.products.stores).to eq([vacuum.store])
      end
    end
  end
end
