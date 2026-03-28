# frozen_string_literal: true

class StoreHealthJob < ApplicationJob
  queue_as :default

  def perform
    stores = Product.distinct.pluck(:store).compact.reject(&:blank?)

    stores.each do |store|
      compute_health(store)
    end
  end

  private

  def compute_health(store)
    now = Time.current

    # Products updated in last 24h
    updated_24h = Product.where(store: store)
                         .where('updated_at >= ?', now - 24.hours)
                         .count

    # Average discount this week vs last week
    this_week_avg = Product.where(store: store)
                           .where('updated_at >= ?', now - 7.days)
                           .where('discount > 0')
                           .average(:discount)&.to_f || 0.0

    last_week_avg = Product.where(store: store)
                           .where('updated_at >= ? AND updated_at < ?', now - 14.days, now - 7.days)
                           .where('discount > 0')
                           .average(:discount)&.to_f || 0.0

    discount_trend = if last_week_avg > 0
                       ((this_week_avg - last_week_avg) / last_week_avg * 100).round(1)
                     else
                       0.0
                     end

    # Out of stock rate
    total_products = Product.where(store: store).count
    out_of_stock   = Product.where(store: store, in_stock: false).count
    oos_rate = total_products > 0 ? (out_of_stock.to_f / total_products * 100).round(1) : 0.0

    # Determine health status
    health_status = if updated_24h == 0
                      'stale'
                    elsif discount_trend < -10 || oos_rate > 50
                      'declining'
                    else
                      'healthy'
                    end

    CrawlLog.create!(
      store:            store,
      products_found:   total_products,
      products_updated: updated_24h,
      products_new:     0,
      duration_seconds: 0.0,
      crawled_at:       now,
      health_status:    health_status
    )
  end
end
