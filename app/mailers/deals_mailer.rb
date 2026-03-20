# frozen_string_literal: true

class DealsMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def weekly_digest(subscriber, deals)
    @subscriber = subscriber
    @deals = deals
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @unsubscribe_url = "#{@site_url}/unsubscribe?token=#{subscriber.unsubscribe_token}"

    mail(
      to: subscriber.email,
      subject: "🔥 This Week's Top Deals on OzVFY"
    )
  end

  def price_alert(alert)
    @alert = alert
    @product = alert.product
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')

    mail(
      to: alert.email,
      subject: "🚨 Price Drop Alert: #{@product.name} is now $#{@product.price}"
    )
  end
end
