# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupExpiredDealsJob, type: :job do
  def make_product(attrs = {})
    Product.create!({
      name: 'Test', price: 10.0, store: 'JB Hi-Fi',
      store_product_id: "sp-#{SecureRandom.hex(4)}",
      expired: false
    }.merge(attrs))
  end

  describe '#perform' do
    it 'expires products older than 3 days not recently updated' do
      p = make_product(updated_at: 5.days.ago, created_at: 5.days.ago)
      Product.where(id: p.id).update_all(updated_at: 5.days.ago)
      CleanupExpiredDealsJob.new.perform
      expect(p.reload.expired).to be true
      expect(p.reload.expiry_reason).to eq('age')
    end

    it 'does not expire products updated recently' do
      p = make_product(updated_at: 1.hour.ago, created_at: 10.days.ago)
      CleanupExpiredDealsJob.new.perform
      expect(p.reload.expired).to be false
    end

    it 'returns a hash with age and stale_price counts' do
      result = CleanupExpiredDealsJob.new.perform
      expect(result).to have_key(:age)
      expect(result).to have_key(:stale_price)
    end
  end
end
