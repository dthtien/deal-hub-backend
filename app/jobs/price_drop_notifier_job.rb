# frozen_string_literal: true

class PriceDropNotifierJob < ApplicationJob
  sidekiq_options retry: 2

  MINIMUM_DROP_PERCENT = 5

  def perform
    dropped_products.find_each do |product|
      notify_alert_subscribers(product)
      notify_saved_deal_users(product)
    end
  end

  private

  def dropped_products
    Product
      .joins(:price_histories)
      .where(expired: false)
      .where('products.price > 0')
      .where(
        'products.old_price > 0 AND ' \
        '((products.old_price - products.price) / products.old_price) * 100 > ?',
        MINIMUM_DROP_PERCENT
      )
      .where(
        'price_histories.recorded_at > ?', 24.hours.ago
      )
      .distinct
  end

  def notify_alert_subscribers(product)
    product.price_alerts.active.find_each do |alert|
      next unless product.price.to_f <= alert.target_price.to_f

      DealsMailer.price_alert(alert).deliver_later
      alert.trigger!
    end
  end

  def notify_saved_deal_users(product)
    SavedDeal.where(product: product).includes(:user).find_each do |saved_deal|
      user = saved_deal.user
      next if user.email.blank?
      next if already_alerted?(user.email, product)

      alert = PriceAlert.create!(
        email: user.email,
        product: product,
        target_price: product.price,
        triggered: true,
        triggered_at: Time.current
      )

      DealsMailer.price_alert(alert).deliver_later
    end
  end

  def already_alerted?(email, product)
    PriceAlert.where(email: email, product: product)
              .where('triggered_at > ?', 24.hours.ago)
              .exists?
  end
end
