# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AffiliateConfig, :model, type: :model do
  describe 'validations' do
    subject { build(:affiliate_config, store: Product::STORES.first) }

    it { is_expected.to validate_presence_of(:store) }
    it { is_expected.to validate_presence_of(:param_name) }
    it { is_expected.to validate_presence_of(:param_value) }
    it { is_expected.to validate_uniqueness_of(:store) }

    it 'is invalid with a store not in Product::STORES' do
      config = build(:affiliate_config, store: 'Unknown Store')
      expect(config).not_to be_valid
      expect(config.errors[:store]).to be_present
    end

    it 'is valid with a store in Product::STORES' do
      config = build(:affiliate_config, store: Product::STORES.first)
      expect(config).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_config) { create(:affiliate_config, store: Product::STORES[0], active: true) }
    let!(:inactive_config) { create(:affiliate_config, store: Product::STORES[1], active: false) }

    describe '.active' do
      it 'returns only active configs' do
        expect(described_class.active).to include(active_config)
        expect(described_class.active).not_to include(inactive_config)
      end
    end
  end

  describe '.as_map' do
    let!(:active_config) do
      create(:affiliate_config, store: Product::STORES[0], param_name: 'aff', param_value: '999', active: true)
    end
    let!(:inactive_config) do
      create(:affiliate_config, store: Product::STORES[1], param_name: 'ref', param_value: '000', active: false)
    end

    it 'returns a hash of active configs keyed by store' do
      result = described_class.as_map
      expect(result).to have_key(Product::STORES[0])
      expect(result[Product::STORES[0]]).to eq({ param: 'aff', value: '999' })
    end

    it 'excludes inactive configs' do
      expect(described_class.as_map).not_to have_key(Product::STORES[1])
    end
  end
end
