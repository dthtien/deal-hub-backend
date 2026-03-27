# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    def index
      # Daily new products (last 30 days)
      @daily_products = (29.downto(0)).map do |days_ago|
        date = days_ago.days.ago.to_date
        count = Product.where(created_at: date.beginning_of_day..date.end_of_day).count
        { date: date.strftime('%d %b'), count: count }
      end

      # Top 10 most clicked deals
      @top_clicked = Product
        .joins(:click_trackings)
        .group('products.id', 'products.name', 'products.store')
        .order('COUNT(click_trackings.id) DESC')
        .limit(10)
        .pluck('products.id', 'products.name', 'products.store', 'COUNT(click_trackings.id) AS click_count')
        .map { |id, name, store, cnt| { id: id, name: name, store: store, click_count: cnt } }

      # Top 10 most viewed deals
      @top_viewed = Product
        .order(view_count: :desc)
        .limit(10)
        .pluck(:id, :name, :store, :view_count)
        .map { |id, name, store, vc| { id: id, name: name, store: store, view_count: vc } }

      # Subscriber growth (last 30 days)
      @subscriber_growth = (29.downto(0)).map do |days_ago|
        date = days_ago.days.ago.to_date
        count = Subscriber.where(created_at: date.beginning_of_day..date.end_of_day).count
        { date: date.strftime('%d %b'), count: count }
      end

      # Crawl success rate per store
      today_start = Time.current.beginning_of_day
      stores = Product.distinct.pluck(:store).compact.sort
      @crawl_stats = stores.map do |store|
        total   = Product.where(store: store).count
        updated = Product.where(store: store).where('updated_at >= ?', today_start).count
        rate    = total > 0 ? (updated.to_f / total * 100).round(1) : 0
        { store: store, total: total, updated_today: updated, success_rate: rate }
      end.sort_by { |s| -s[:success_rate] }
    end
  end
end
