# frozen_string_literal: true

class CleanupExpiredDealsJob < ApplicationJob
  queue_as :default

  ACTIVE_STORES      = Product::STORES.freeze
  STALE_PRICE_DAYS   = 30
  AGE_THRESHOLD_DAYS = 3

  def perform
    age_count    = expire_by_age!
    stale_count  = expire_stale_prices!
    Rails.logger.info "CleanupExpiredDealsJob: age=#{age_count} stale_price=#{stale_count}"
    { age: age_count, stale_price: stale_count }
  end

  private

  def expire_by_age!
    # Products not updated in last crawl cycle (older than AGE_THRESHOLD_DAYS)
    # Skip those updated recently (crawl likely touched them)
    candidates = Product.where(store: ACTIVE_STORES)
                        .where(expired: false)
                        .where("updated_at < ?", AGE_THRESHOLD_DAYS.days.ago)

    count = 0
    candidates.find_each do |product|
      # If product was updated in last crawl (within 24h), keep active
      next if product.updated_at >= 1.day.ago

      product.update_columns(expired: true, status: 'expired', expiry_reason: 'age')
      count += 1
    end
    count
  end

  def expire_stale_prices!
    # Products where price hasn't changed in STALE_PRICE_DAYS days
    stale_cutoff = STALE_PRICE_DAYS.days.ago
    count = 0

    Product.where(store: ACTIVE_STORES)
           .where(expired: false)
           .find_each do |product|
      histories = product.price_histories.where("recorded_at >= ?", stale_cutoff).pluck(:price)
      next if histories.empty?

      # If there's only one unique price over the last 30 days AND product is old, consider stale
      unique_prices = histories.map(&:to_f).uniq
      next unless unique_prices.size == 1

      # Also require the product itself to be at least 30 days old
      next unless product.created_at < stale_cutoff

      # Skip if recently updated (crawled)
      next if product.updated_at >= 7.days.ago

      product.update_columns(expired: true, status: 'expired', expiry_reason: 'stale_price')
      count += 1
    end
    count
  end
end
