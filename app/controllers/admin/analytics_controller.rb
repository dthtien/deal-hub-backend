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

    def affiliate
      stores = Product.where(expired: false)
                      .group(:store)
                      .select(
                        :store,
                        'COUNT(*) AS product_count',
                        'SUM(view_count) AS total_views',
                        'AVG(price) AS avg_price'
                      )

      @affiliate_stats = stores.map do |row|
        store = row.store
        products_for_store = Product.where(store: store, expired: false)
        click_count = ClickTracking.where(store: store).count
        avg_price = row.avg_price.to_f
        sample = products_for_store.first
        network = sample&.affiliate_network_value || 'commission_factory'
        rate = sample&.commission_rate_value || 0.04
        estimated_commission = (click_count * avg_price * rate).round(2)

        {
          store: store,
          affiliate_network: network,
          commission_rate: rate,
          click_count: click_count,
          avg_price: avg_price.round(2),
          product_count: row.product_count.to_i,
          estimated_commission: estimated_commission
        }
      end.sort_by { |s| -s[:estimated_commission] }

      render json: { affiliate_stats: @affiliate_stats }
    end

    def revenue
      now = Time.current
      this_month_start = now.beginning_of_month
      last_month_start = 1.month.ago.beginning_of_month
      last_month_end   = last_month_start.end_of_month
      conversion_rate  = 0.02

      this_month_clicks = ClickTracking.where('created_at >= ?', this_month_start).count
      last_month_clicks = ClickTracking.where(created_at: last_month_start..last_month_end).count

      avg_product_price = Product.where(expired: false).average(:price)&.to_f&.round(2) || 0.0
      avg_commission_rate = 0.04

      estimated_revenue = (this_month_clicks * avg_commission_rate * avg_product_price * conversion_rate).round(2)
      last_month_revenue = (last_month_clicks * avg_commission_rate * avg_product_price * conversion_rate).round(2)

      mom_change = if last_month_revenue > 0
        (((estimated_revenue - last_month_revenue) / last_month_revenue) * 100).round(1)
      else
        0.0
      end

      stores = Product.where(expired: false)
                      .group(:store)
                      .select(:store, 'COUNT(*) AS product_count', 'AVG(price) AS avg_price')

      per_store = stores.map do |row|
        store = row.store
        click_count = ClickTracking.where(store: store).where('created_at >= ?', this_month_start).count
        sample = Product.where(store: store, expired: false).first
        rate = sample&.commission_rate_value || avg_commission_rate
        store_avg_price = row.avg_price.to_f
        store_revenue = (click_count * rate * store_avg_price * conversion_rate).round(2)
        {
          store: store,
          clicks_this_month: click_count,
          avg_price: store_avg_price.round(2),
          commission_rate: rate,
          estimated_revenue: store_revenue
        }
      end.sort_by { |s| -s[:estimated_revenue] }

      render json: {
        this_month: {
          clicks: this_month_clicks,
          avg_commission_rate: avg_commission_rate,
          avg_product_price: avg_product_price,
          conversion_rate: conversion_rate,
          estimated_revenue: estimated_revenue
        },
        last_month: {
          clicks: last_month_clicks,
          estimated_revenue: last_month_revenue
        },
        mom_change_percent: mom_change,
        per_store: per_store
      }
    end

    def coupons
      all_coupons = Coupon.all.order(Arel.sql('CASE WHEN reveal_count > 0 THEN (used_count::float / reveal_count) ELSE 0 END DESC'))

      expiring_soon_ids = Coupon.where('expires_at IS NOT NULL AND expires_at BETWEEN ? AND ?', Time.current, 7.days.from_now).pluck(:id).to_set

      coupon_data = all_coupons.map do |c|
        conversion = c.reveal_count > 0 ? (c.used_count.to_f / c.reveal_count * 100).round(1) : 0.0
        {
          id: c.id,
          code: c.code,
          store: c.store,
          description: c.description,
          discount_value: c.discount_value,
          discount_type: c.discount_type,
          discount_label: c.discount_label,
          reveal_count: c.reveal_count,
          use_count: c.used_count,
          conversion_rate: conversion,
          expires_at: c.expires_at,
          expiring_soon: expiring_soon_ids.include?(c.id),
          active: c.active?,
          verified: c.verified
        }
      end

      top_by_conversion = coupon_data.select { |c| c[:reveal_count] > 0 }
                                     .sort_by { |c| -c[:conversion_rate] }
                                     .first(10)

      expiring_soon = coupon_data.select { |c| c[:expiring_soon] }
                                 .sort_by { |c| c[:expires_at] }

      render json: {
        coupons: coupon_data,
        top_by_conversion: top_by_conversion,
        expiring_soon: expiring_soon
      }
    end

    def attribution
      # Breakdown by utm_source
      by_source = ClickTracking
        .where.not(utm_source: nil)
        .group(:utm_source)
        .order(Arel.sql('COUNT(*) DESC'))
        .count
        .map { |src, cnt| { utm_source: src, clicks: cnt } }

      # Breakdown by utm_medium
      by_medium = ClickTracking
        .where.not(utm_medium: nil)
        .group(:utm_medium)
        .order(Arel.sql('COUNT(*) DESC'))
        .count
        .map { |med, cnt| { utm_medium: med, clicks: cnt } }

      # Breakdown by utm_campaign
      by_campaign = ClickTracking
        .where.not(utm_campaign: nil)
        .group(:utm_campaign)
        .order(Arel.sql('COUNT(*) DESC'))
        .count
        .map { |camp, cnt| { utm_campaign: camp, clicks: cnt } }

      total = ClickTracking.count
      attributed = ClickTracking.with_utm.count
      unattributed = total - attributed

      render json: {
        summary: { total: total, attributed: attributed, unattributed: unattributed },
        by_source: by_source,
        by_medium: by_medium,
        by_campaign: by_campaign
      }
    end

    def click_heatmap
      rows = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT
          EXTRACT(hour FROM created_at)::int AS hour,
          EXTRACT(dow  FROM created_at)::int AS dow,
          COUNT(*) AS count
        FROM click_trackings
        GROUP BY hour, dow
        ORDER BY dow, hour
      SQL

      # Build 7x24 matrix [dow][hour] = count
      matrix = Array.new(7) { Array.new(24, 0) }
      rows.each do |row|
        h   = row['hour'].to_i
        d   = row['dow'].to_i
        cnt = row['count'].to_i
        matrix[d][h] = cnt if d.between?(0, 6) && h.between?(0, 23)
      end

      render json: {
        matrix: matrix,
        days:   %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday],
        hours:  (0..23).map { |h| format('%02d:00', h) }
      }
    end
  end
end
