# frozen_string_literal: true

class PriceAlertMailer < ApplicationMailer
  def price_dropped(alert)
    @alert = alert
    @product = alert.product

    mail(
      to: alert.email,
      subject: "🎉 Price drop! #{@product.name} is now $#{@product.price}"
    )
  end
end
