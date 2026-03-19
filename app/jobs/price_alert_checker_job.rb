# frozen_string_literal: true

class PriceAlertCheckerJob < ApplicationJob
  def perform
    PriceAlert.active.includes(:product).find_each do |alert|
      next unless alert.product.price.to_f <= alert.target_price.to_f

      DealsMailer.price_alert(alert).deliver_later
      alert.trigger!
    end
  end
end
