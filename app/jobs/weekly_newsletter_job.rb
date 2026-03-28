# frozen_string_literal: true

class WeeklyNewsletterJob < ApplicationJob
  def perform
    deals = Product
      .includes(:ai_deal_analysis)
      .where(expired: false)
      .where('discount > 0')
      .where('updated_at >= ?', 7.days.ago)
      .order(deal_score: :desc, discount: :desc)
      .limit(10)

    return if deals.empty?

    # Top 5 by discount
    top_by_discount = Product
      .where(expired: false)
      .where('discount > 0')
      .where('updated_at >= ?', 7.days.ago)
      .order(discount: :desc)
      .limit(5)

    # Deal of the week
    aest_week = Time.current.in_time_zone('Australia/Sydney').to_date.beginning_of_week
    deal_of_week = Rails.cache.fetch("deal_of_the_week_#{aest_week}", expires_in: 8.days) do
      candidates = Product.where(expired: false)
                          .where('products.created_at >= ?', 7.days.ago)
                          .where.not(image_url: [nil, ''])
                          .order(deal_score: :desc)
                          .limit(10)
                          .to_a
      candidates[aest_week.cweek % [candidates.size, 1].max]
    end

    # Flash deals ending soon (within 48 hours)
    flash_deals_ending = Product
      .where(expired: false)
      .where('flash_expires_at IS NOT NULL AND flash_expires_at < ?', 48.hours.from_now)
      .where('flash_expires_at > ?', Time.current)
      .order(:flash_expires_at)
      .limit(5)

    # Top 5 price drops since last week
    price_drop_products = Product
      .joins(:price_histories)
      .where(expired: false)
      .where('price_histories.recorded_at >= ?', 7.days.ago)
      .where('price_histories.old_price > price_histories.price')
      .select(
        'products.*',
        'MAX(price_histories.old_price - price_histories.price) AS drop_amount'
      )
      .group('products.id')
      .order(Arel.sql('drop_amount DESC'))
      .limit(5)

    # New stores this week (stores that had NO products before this week)
    all_store_names = Product.distinct.pluck(:store).compact.reject(&:blank?)
    new_this_week_stores = Product
      .where('created_at >= ?', 7.days.ago)
      .distinct
      .pluck(:store)
      .compact
      .reject(&:blank?)
      .select do |store|
        Product.where(store: store).where('created_at < ?', 7.days.ago).none?
      end

    # Price drop alerts summary
    price_drops_count = PriceHistory
      .where('recorded_at >= ?', 7.days.ago)
      .where('old_price > price')
      .distinct
      .count(:product_id)

    Subscriber.active.find_each do |subscriber|
      DealsMailer.weekly_digest(
        subscriber,
        deals,
        top_by_discount: top_by_discount,
        deal_of_week: deal_of_week,
        new_stores: new_this_week_stores,
        price_drops_count: price_drops_count,
        flash_deals_ending: flash_deals_ending,
        price_drop_products: price_drop_products
      ).deliver_later
    end

    Rails.logger.info "WeeklyNewsletterJob: sent to #{Subscriber.active.count} subscribers"
  end
end
