# frozen_string_literal: true

class DealsMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def weekly_digest(subscriber, deals, top_by_discount: [], deal_of_week: nil, new_stores: [], price_drops_count: 0)
    @subscriber = subscriber
    @deals = deals
    @top_by_discount = top_by_discount
    @deal_of_week = deal_of_week
    @new_stores = new_stores
    @price_drops_count = price_drops_count
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @unsubscribe_url = "#{@site_url}/unsubscribe?token=#{subscriber.unsubscribe_token}"

    mail(
      to: subscriber.email,
      subject: "🔥 This Week's Top Deals on OzVFY"
    )
  end

  def keyword_alert(alert, product)
    @alert = alert
    @product = product
    @keyword = alert.keyword
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @deal_url = "#{@site_url}/deals/#{@product.id}"
    @unsubscribe_url = "#{@site_url}/unsubscribe"

    mail(
      to: alert.email,
      subject: "New deal matching \"#{@keyword}\": #{@product.name}"
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
