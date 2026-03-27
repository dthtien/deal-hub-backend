# frozen_string_literal: true

class CleanupExpiredCouponsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = Coupon.where(active: true)
                          .where('expires_at IS NOT NULL AND expires_at < ?', Time.current)
                          .update_all(active: false)

    Rails.logger.info "CleanupExpiredCouponsJob: marked #{expired_count} coupons as inactive"
  end
end
