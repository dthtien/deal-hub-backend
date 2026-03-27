# frozen_string_literal: true

class PruneOldPriceHistoriesJob < ApplicationJob
  queue_as :low

  def perform
    cutoff = 90.days.ago

    # Only prune histories for non-expired products
    non_expired_product_ids = Product.where(expired: false).select(:id)

    count = PriceHistory.where(product_id: non_expired_product_ids)
                        .where("recorded_at < ?", cutoff)
                        .delete_all

    Rails.logger.info "PruneOldPriceHistoriesJob: deleted #{count} old price history records"
    count
  end
end
