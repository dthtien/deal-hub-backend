# frozen_string_literal: true

class GoingFastDetectorJob < ApplicationJob
  queue_as :default

  CRON = '*/15 * * * *'
  HEAT_INDEX_THRESHOLD = 300
  # Products updated recently with view_count > 50 are treated as "going fast"
  # (true delta tracking would require view_count in deal_score_histories)
  VIEW_COUNT_THRESHOLD = 50
  RECENT_WINDOW = 1.hour
  FLASH_DEAL_DISCOUNT_THRESHOLD = 30

  def perform
    fast_products = Product
      .where(expired: false)
      .where(
        'heat_index > ? OR (view_count >= ? AND updated_at >= ?)',
        HEAT_INDEX_THRESHOLD,
        VIEW_COUNT_THRESHOLD,
        RECENT_WINDOW.ago
      )

    fast_ids = fast_products.pluck(:id)

    Product.where(id: fast_ids).update_all(going_fast: true) if fast_ids.any?

    Product.where(going_fast: true)
           .where.not(id: fast_ids)
           .update_all(going_fast: false)

    # Snapshot heat_index for trending velocity tracking
    snapshot_heat_indices(fast_ids)

    # Send store wishlist flash deal alerts
    notify_store_wishlist_flash_deals(fast_products)
  end

  private

  def snapshot_heat_indices(product_ids)
    return if product_ids.empty?

    Product.where(id: product_ids).find_each do |product|
      product.snapshot_heat_index!
    rescue => e
      Rails.logger.warn "GoingFastDetectorJob - snapshot error for product #{product.id}: #{e.message}"
    end
  end

  def notify_store_wishlist_flash_deals(flash_products)
    flash_deals = flash_products
      .where('discount >= ? OR (flash_expires_at IS NOT NULL AND flash_expires_at > ?)',
             FLASH_DEAL_DISCOUNT_THRESHOLD, Time.current)
      .select(:id, :name, :store, :discount, :price, :flash_expires_at)

    return if flash_deals.empty?

    flash_deals.group_by(&:store).each do |store_name, products|
      followers = StoreFollow.where(store_name: store_name).pluck(:session_id)
      next if followers.empty?

      products.each do |product|
        message = "Flash deal at #{store_name}! #{product.name.truncate(60)} is #{product.discount.to_i}% off for next 24h"
        payload = {
          title: "Flash deal at #{store_name}!",
          body: message,
          url: "/deals/#{product.id}"
        }
        send_push_to_sessions(followers, payload)
      end
    end
  rescue => e
    Rails.logger.warn "GoingFastDetectorJob - wishlist alert error: #{e.message}"
  end

  def send_push_to_sessions(session_ids, payload)
    session_ids.each do |session_id|
      subs = PushSubscription.where(session_id: session_id)
      subs.find_each do |sub|
        WebPushService.send_personalised(
          sub,
          title: payload[:title],
          body: payload[:body],
          url: payload[:url]
        )
      rescue => e
        Rails.logger.warn "GoingFastDetectorJob - push error for session #{session_id}: #{e.message}"
      end
    end
  end
end
