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
        stats:            @stats,
        top_stores:       @top_stores.map { |s, c| { store: s, count: c } },
        recent_products:  @recent_products.map { |p| { id: p.id, name: p.name.truncate(50), store: p.store, price: p.price } },
        daily_stats:      @daily_stats.map { |label, count| { label: label, count: count } },
        crawl_running:    @crawl_running,
        health:           @health,
        recent_activity:  @recent_activity,
        generated_at:     Time.current.iso8601
      }
    end

    def quick_action
      action = params[:action_name].to_s
      result = case action
               when 'run_crawl'
                 Crawlers::DistributeJob.perform_later
                 { message: 'Crawl job queued.' }
               when 'clear_cache'
                 Rails.cache.clear
                 { message: 'Cache cleared.' }
               when 'send_digest'
                 WatchlistDigestJob.perform_later
                 { message: 'Digest job queued.' }
               else
                 { error: "Unknown action: #{action}" }
               end
      render json: result
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

      @crawl_running = CrawlLog.where('crawled_at >= ?', 5.minutes.ago).exists?

      # Health indicators
      sidekiq_queue_depth = begin
        require 'sidekiq/api'
        Sidekiq::Queue.all.sum(&:size)
      rescue
        nil
      end

      db_size_bytes = begin
        result = ActiveRecord::Base.connection.execute(
          "SELECT pg_database_size(current_database()) AS size"
        )
        result.first['size'].to_i
      rescue
        nil
      end

      @health = {
        sidekiq_queue_depth: sidekiq_queue_depth,
        db_size_mb: db_size_bytes ? (db_size_bytes.to_f / 1.megabyte).round(1) : nil,
        active_deals: @stats[:active],
        pending_submissions: @stats[:submissions]
      }

      # Recent activity feed: last 10 events across crawls, alerts, signups
      crawl_events = CrawlLog.order(crawled_at: :desc).limit(5).map do |c|
        { type: 'crawl', message: "Crawl: #{c.store} - #{c.products_new || 0} new, #{c.products_updated || 0} updated", at: c.crawled_at&.iso8601 }
      end

      signup_events = Subscriber.order(created_at: :desc).limit(3).map do |s|
        { type: 'signup', message: "New subscriber: #{s.email.to_s.gsub(/(?<=.).(?=[^@]*@)/, '*')}", at: s.created_at&.iso8601 }
      end

      @recent_activity = (crawl_events + signup_events)
                           .sort_by { |e| e[:at].to_s }
                           .reverse
                           .first(10)
    end
  end
end
