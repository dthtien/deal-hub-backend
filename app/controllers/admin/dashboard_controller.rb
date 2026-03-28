# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      load_dashboard_data
      render :index
    end

    def stats
      load_dashboard_data
      render json: {
        stats:           @stats,
        top_stores:      @top_stores.map { |s, c| { store: s, count: c } },
        recent_products: @recent_products.map { |p| { id: p.id, name: p.name.truncate(50), store: p.store, price: p.price } },
        daily_stats:     @daily_stats.map { |label, count| { label: label, count: count } },
        crawl_running:   @crawl_running,
        generated_at:    Time.current.iso8601
      }
    end

    private

    def load_dashboard_data
      @stats = {
        products:    Product.count,
        active:      Product.where(expired: false).count,
        stores:      Product.distinct.count(:store),
        subscribers: Subscriber.count,
        coupons:     Coupon.active.count,
        votes:       Vote.count,
        submissions: DealSubmission.pending.count,
        clicks:      ClickTracking.count
      }

      @top_stores = Product.where(expired: false)
                           .group(:store)
                           .order('count_id desc')
                           .limit(10)
                           .count(:id)

      @recent_products = Product.order(created_at: :desc).limit(10)

      @daily_stats = (6.downto(0)).map do |days_ago|
        date = days_ago.days.ago.to_date
        count = Product.where(created_at: date.beginning_of_day..date.end_of_day).count
        [date.strftime('%d %b'), count]
      end

      @top_deals = Product.order(Arel.sql("(SELECT COUNT(*) FROM click_trackings WHERE click_trackings.product_id = products.id) DESC")).limit(5)

      @recent_votes = Vote.includes(:product).order(created_at: :desc).limit(10)

      # Crawl running: check if any CrawlLog was created in the last 5 minutes
      @crawl_running = CrawlLog.where('crawled_at >= ?', 5.minutes.ago).exists?
    end
  end
end
