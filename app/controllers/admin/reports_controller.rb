# frozen_string_literal: true

module Admin
  class ReportsController < BaseController
    def stores
      week_ago = 1.week.ago
      two_weeks_ago = 2.weeks.ago

      # Per-store aggregated stats
      store_names = Product.distinct.pluck(:store).compact.sort

      @store_stats = store_names.map do |store|
        products = Product.where(store: store)
        active   = products.where(expired: false)

        total_products  = products.count
        active_products = active.count
        avg_discount    = active.where('discount > 0').average(:discount)&.to_f&.round(1) || 0.0

        total_views  = active.sum(:view_count).to_i
        total_clicks = ClickTracking.joins(:product).where(products: { store: store }).count
        ctr = total_views > 0 ? (total_clicks.to_f / total_views * 100).round(1) : 0.0

        last_log = CrawlLog.where(store: store).order(crawled_at: :desc).first
        last_crawled = last_log&.crawled_at&.strftime('%d %b %Y %H:%M') || 'Never'

        this_week_count = products.where('created_at >= ?', week_ago).count
        last_week_count = products.where('created_at >= ? AND created_at < ?', two_weeks_ago, week_ago).count
        trend_diff = this_week_count - last_week_count

        {
          store: store,
          total_products: total_products,
          active_products: active_products,
          avg_discount: avg_discount,
          ctr: ctr,
          last_crawled: last_crawled,
          this_week: this_week_count,
          last_week: last_week_count,
          trend_diff: trend_diff
        }
      end

      @store_stats.sort_by! { |s| -s[:active_products] }
      render :stores
    end
  end
end
