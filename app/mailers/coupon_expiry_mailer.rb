# frozen_string_literal: true

class CouponExpiryMailer < ApplicationMailer
  def expiry_reminder(subscriber, coupons)
    @subscriber = subscriber
    @coupons    = coupons
    @site_url   = 'https://www.ozvfy.com'

    mail(
      to:      subscriber.email,
      subject: "Heads up - #{coupons.size} coupon#{coupons.size == 1 ? '' : 's'} expiring in 24 hours"
    )
  end
end
