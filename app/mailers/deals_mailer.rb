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
    @current_price = @product.price
    @old_price = @product.old_price.to_f.positive? ? @product.old_price : alert.target_price
    @discount = @product.discount
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @deal_url = "#{@site_url}/deals/#{@product.id}"

    mail(
      to: alert.email,
      subject: "Price Drop! #{@product.name} is now $#{@current_price} (#{@discount.to_i}% off)"
    )
  end
end
