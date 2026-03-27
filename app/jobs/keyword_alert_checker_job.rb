# frozen_string_literal: true

class KeywordAlertCheckerJob < ApplicationJob
  queue_as :default

  def perform(product_ids = nil)
    products = if product_ids.present?
                 Product.where(id: product_ids)
               else
                 Product.where('created_at >= ?', 2.hours.ago)
               end

    keyword_alerts = PriceAlert.keyword_alerts.active

    products.find_each do |product|
      keyword_alerts.find_each do |alert|
        next unless product.name.downcase.include?(alert.keyword.downcase)

        DealsMailer.keyword_alert(alert, product).deliver_later
        alert.trigger!
      end
    end
  end
end
