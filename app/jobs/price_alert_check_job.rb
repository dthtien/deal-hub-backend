# frozen_string_literal: true

class PriceAlertCheckJob < ApplicationJob
  queue_as :default

  def perform
    PriceAlert.active.includes(:product).find_each do |alert|
      next unless alert.product.price <= alert.target_price

      PriceAlertMailer.price_dropped(alert).deliver_later
      alert.update!(status: :triggered, triggered_at: Time.current)
    end
  end
end
