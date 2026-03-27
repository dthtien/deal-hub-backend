# frozen_string_literal: true

class CleanupExpiredDealsJob < ApplicationJob
  queue_as :default

  ACTIVE_STORES = Product::STORES.freeze

  def perform
    count = Product.where(store: ACTIVE_STORES)
                   .where(expired: false)
                   .where("updated_at < ?", 3.days.ago)
                   .update_all(expired: true)
    Rails.logger.info "CleanupExpiredDealsJob: marked #{count} products as expired"
    count
  end
end
