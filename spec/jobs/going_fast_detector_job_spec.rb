# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoingFastDetectorJob, type: :job do
  def make_product(attrs = {})
    Product.create!({
      name: 'Test', price: 10.0, store: 'JB Hi-Fi',
      store_product_id: "sp-#{SecureRandom.hex(4)}",
      expired: false
    }.merge(attrs))
  end

  # Move the product outside RECENT_WINDOW so only the heat_index branch can match
  def make_stale(product)
    Product.where(id: product.id).update_all(updated_at: 2.days.ago)
  end

  describe '#perform' do
    it 'flags a product whose heat_index is above the threshold' do
      p = make_product(view_count: 1000)
      p.votes.create!(session_id: 'voter-1', value: 1)
      p.click_trackings.create!(store: p.store, clicked_at: Time.current)
      make_stale(p)

      expect(p.heat_index).to be > GoingFastDetectorJob::HEAT_INDEX_THRESHOLD
      expect { GoingFastDetectorJob.new.perform }
        .to change { DealScoreHistory.where(product_id: p.id).count }.by(1)
      expect(p.reload.going_fast).to be true
    end

    it 'does not flag a stale product whose heat_index is not above the threshold' do
      p = make_product(view_count: 1000)
      p.votes.create!(session_id: 'voter-1', value: -1)
      make_stale(p)

      GoingFastDetectorJob.new.perform
      expect(p.reload.going_fast).to be false
    end

    it 'flags recently updated products with enough views' do
      p = make_product(view_count: GoingFastDetectorJob::VIEW_COUNT_THRESHOLD)
      GoingFastDetectorJob.new.perform
      expect(p.reload.going_fast).to be true
    end

    it 'clears going_fast on products that no longer qualify' do
      p = make_product(going_fast: true)
      GoingFastDetectorJob.new.perform
      expect(p.reload.going_fast).to be false
    end
  end
end
