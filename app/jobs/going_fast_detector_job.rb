# frozen_string_literal: true

class GoingFastDetectorJob < ApplicationJob
  queue_as :default

  CRON = '*/15 * * * *'
  HEAT_INDEX_THRESHOLD = 300
  # Products updated recently with view_count > 50 are treated as "going fast"
  # (true delta tracking would require view_count in deal_score_histories)
  VIEW_COUNT_THRESHOLD = 50
  RECENT_WINDOW = 1.hour

  def perform
    fast_ids = Product
      .where(expired: false)
      .where(
        'heat_index > ? OR (view_count >= ? AND updated_at >= ?)',
        HEAT_INDEX_THRESHOLD,
        VIEW_COUNT_THRESHOLD,
        RECENT_WINDOW.ago
      )
      .pluck(:id)

    Product.where(id: fast_ids).update_all(going_fast: true) if fast_ids.any?

    Product.where(going_fast: true)
           .where.not(id: fast_ids)
           .update_all(going_fast: false)
  end
end
