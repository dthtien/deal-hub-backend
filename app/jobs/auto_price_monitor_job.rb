# frozen_string_literal: true

class AutoPriceMonitorJob < ApplicationJob
  queue_as :default

  DROP_THRESHOLD = 0.10 # 10% price drop

  def perform
    Rails.logger.info("[AutoPriceMonitor] Starting automated price monitoring")
    flagged = 0

    Product.where(expired: false).find_each(batch_size: 200) do |product|
      check_product(product)
      flagged += 1
    rescue => e
      Rails.logger.error("[AutoPriceMonitor] Error checking product #{product.id}: #{e.message}")
    end

    Rails.logger.info("[AutoPriceMonitor] Completed - checked products")
  end

  private

  def check_product(product)
    last_history = product.price_histories.order(recorded_at: :desc).second
    return unless last_history

    current_price = product.price.to_f
    previous_price = last_history.price.to_f
    return if previous_price <= 0 || current_price <= 0

    drop_ratio = (previous_price - current_price) / previous_price
    return unless drop_ratio >= DROP_THRESHOLD

    # Check if active price alert already exists at this level
    active_alert_exists = PriceAlert.where(
      product_id: product.id,
      status: 'active'
    ).where('target_price >= ?', current_price).exists?

    return if active_alert_exists

    # Create community alert notification
    create_community_alert(product, current_price, previous_price, drop_ratio)
  end

  def create_community_alert(product, current_price, previous_price, drop_ratio)
    pct = (drop_ratio * 100).round(1)
    PriceAlert.create!(
      product_id: product.id,
      email: 'community@ozvfy.com.au',
      target_price: current_price,
      status: 'active',
      keyword: "community_alert:#{pct}pct_drop"
    )
    Rails.logger.info("[AutoPriceMonitor] Community alert created for product #{product.id} - #{pct}% drop ($#{previous_price} -> $#{current_price})")
  end
end
