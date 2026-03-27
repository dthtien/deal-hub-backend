# frozen_string_literal: true

class CouponExpiryNotifierJob < ApplicationJob
  queue_as :default

  def perform
    # Find coupons expiring within the next 24 hours
    window_start = Time.current
    window_end   = 24.hours.from_now

    expiring_coupons = Coupon.where(active: true)
                             .where('expires_at > ? AND expires_at <= ?', window_start, window_end)

    return if expiring_coupons.none?

    # Find subscribers with coupon_alerts preference enabled
    alert_subscribers = Subscriber.active.where("preferences->>'coupon_alerts' = 'true'")

    return if alert_subscribers.none?

    alert_subscribers.each do |subscriber|
      begin
        CouponExpiryMailer.expiry_reminder(subscriber, expiring_coupons.to_a).deliver_later
      rescue => e
        Rails.logger.error "CouponExpiryNotifierJob - failed to send to #{subscriber.email}: #{e.message}"
      end
    end

    Rails.logger.info "CouponExpiryNotifierJob - notified #{alert_subscribers.count} subscribers about #{expiring_coupons.count} expiring coupons"
  end
end
