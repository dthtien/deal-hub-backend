# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
      PER_PAGE = 20

      def trending
        data = Rails.cache.fetch('stores_trending_v1', expires_in: 30.minutes) do
          results = ClickTracking
            .where('created_at >= ?', 24.hours.ago)
            .where.not(store: [nil, ''])
            .group(:store)
            .order('COUNT(*) DESC')
            .limit(5)
            .count

          results.map do |store, count|
            {
              name: store,
              click_count: count,
              favicon_url: "https://www.google.com/s2/favicons?domain=#{store.downcase.gsub(/\s+/, '').concat('.com.au')}&sz=64"
            }
          end
        end

        render json: { stores: data }
      end

      def index
        response.set_header('Cache-Control', 'public, max-age=3600')

        stores = Rails.cache.fetch('stores_index_v4', expires_in: 1.hour) do
          # Loyalty score: repeat_clickers / total_unique_clickers per store
          loyalty_by_store = {}
          ClickTracking.where.not(store: [nil, ''], session_id: [nil, ''])
                       .group(:store, :session_id)
                       .count
                       .group_by { |(store, _session), _cnt| store }
                       .each do |store, session_counts|
            total_unique = session_counts.size
            repeat = session_counts.count { |_, cnt| cnt > 1 }
            loyalty_by_store[store] = total_unique > 0 ? (repeat.to_f / total_unique).round(4) : 0.0
          end

          # Aggregate deal_count and avg_discount for all stores in one query
          stats = Product.where(expired: false)
                         .group(:store)
                         .select(
                           :store,
                           'COUNT(*) AS deal_count',
                           'ROUND(AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END)::numeric, 1) AS avg_discount'
                         )
                         .index_by(&:store)

          # Products updated today per store
          today_counts = Product.where(expired: false)
                                .where('updated_at >= ?', Time.current.beginning_of_day)
                                .group(:store)
                                .count

          # In-stock counts per store
          in_stock_counts = Product.where(expired: false, in_stock: true).group(:store).count
          total_counts    = Product.where(expired: false).group(:store).count

          # Aggregate review stats per store in one query
          review_stats = StoreReview
            .group(:store_name)
            .select(:store_name, 'ROUND(AVG(rating)::numeric,1) AS avg_rating', 'COUNT(*) AS review_count')
            .index_by(&:store_name)

          # Single subquery to get the best deal per store (highest discount)
          best_deal_ids = Product
            .where(expired: false)
            .where(store: Product::STORES)
            .select('DISTINCT ON (store) id, store')
            .order('store, discount DESC NULLS LAST')
            .map(&:id)

          best_deals_by_store = Product
            .where(id: best_deal_ids)
            .index_by(&:store)

          result = Product::STORES.map do |store|
            row    = stats[store]
            dc     = row&.deal_count.to_i
            avg    = row&.avg_discount.to_f.round(1)
            best   = best_deals_by_store[store]
            rrow   = review_stats[store]

            total      = total_counts[store].to_i
            today      = today_counts[store].to_i
            in_stock   = in_stock_counts[store].to_i

            deal_freshness = total > 0 ? (today.to_f / total) : 0.0
            stock_rate     = total > 0 ? (in_stock.to_f / total) : 0.0
            store_score    = ((deal_freshness * 40) + (avg * 0.4) + (stock_rate * 20)).round(1)

            latest_health_log = CrawlLog.where(store: store).order(crawled_at: :desc).first
            health_status = latest_health_log&.health_status || 'unknown'

            {
              name:          store,
              deal_count:    dc,
              avg_discount:  avg,
              best_deal:     best&.as_json,
              avg_rating:    rrow&.avg_rating.to_f,
              review_count:  rrow&.review_count.to_i,
              store_score:   store_score,
              loyalty_score: loyalty_by_store[store] || 0.0,
              health_status: health_status,
              last_crawled_at: latest_health_log&.crawled_at&.iso8601
            }
          end

          result.sort_by { |s| -s[:store_score] }
        end

        render json: { stores: stores }
      end

      def compare
        store_names = Array(params[:stores]).first(3).map { |s| URI.decode_www_form_component(s.to_s) }
        if store_names.size < 2
          return render json: { error: 'Provide 2-3 store names' }, status: :unprocessable_entity
        end

        result = store_names.map do |store|
          products = Product.where(store: store, expired: false)
          total = products.count
          avg_discount = products.where('discount > 0').average(:discount)&.to_f&.round(1) || 0.0
          best = products.order(discount: :desc).first
          prices = products.where('price IS NOT NULL').pluck(:price).map(&:to_f)

          # trending_score: clicks in last 24h / total products
          clicks_24h = ClickTracking.where(store: store).where('created_at >= ?', 24.hours.ago).count
          trending_score = total > 0 ? (clicks_24h.to_f / total).round(4) : 0.0

          # freshness: products updated in last 6h / total
          fresh_count = products.where('updated_at >= ?', 6.hours.ago).count
          freshness = total > 0 ? (fresh_count.to_f / total * 100).round(1) : 0.0

          # value_score: avg discount * stock_rate
          in_stock_count = products.where(in_stock: true).count
          stock_rate = total > 0 ? (in_stock_count.to_f / total) : 0.0
          value_score = (avg_discount * stock_rate).round(2)

          {
            store: store,
            total_deals: total,
            avg_discount: avg_discount,
            best_deal: best&.as_json,
            price_range: prices.any? ? { min: prices.min.round(2), max: prices.max.round(2) } : nil,
            trending_score: trending_score,
            freshness: freshness,
            value_score: value_score
          }
        end

        # Compute winners per category
        winners = {}
        %w[avg_discount trending_score freshness value_score].each do |metric|
          values = result.map { |s| [s[:store], s[metric.to_sym]] }
          best_store = values.max_by { |_, v| v.to_f }&.first
          winners[metric] = best_store
        end

        render json: { comparison: result, winners: winners }
      end

      def inventory
        store_name = URI.decode_www_form_component(params[:name])
        products = Product.where(store: store_name)
        total = products.count

        if total.zero?
          return render json: {
            total_products: 0,
            in_stock: 0,
            out_of_stock: 0,
            stock_rate: 0.0
          }
        end

        in_stock = products.where(in_stock: true).count
        out_of_stock = total - in_stock
        stock_rate = (in_stock.to_f / total * 100).round(1)

        render json: {
          total_products: total,
          in_stock:       in_stock,
          out_of_stock:   out_of_stock,
          stock_rate:     stock_rate
        }
      end

      def rating
        store_name = URI.decode_www_form_component(params[:name])
        reviews = StoreReview.for_store(store_name)
        count = reviews.count

        if count.zero?
          return render json: { avg_rating: 0.0, count: 0, distribution: {} }
        end

        avg = reviews.average(:rating)&.to_f&.round(1) || 0.0
        distribution = reviews.group(:rating).count.transform_keys(&:to_s)

        render json: {
          avg_rating: avg,
          count: count,
          distribution: distribution
        }
      end

      def deals
        store_name = URI.decode_www_form_component(params[:name])
        page = (params[:page] || 1).to_i
        offset = (page - 1) * PER_PAGE

        base = Product.where(store: store_name).order(discount: :desc, created_at: :desc)
        total = base.count
        products = base.limit(PER_PAGE).offset(offset)

        # Store stats
        all_store_products = Product.where(store: store_name)
        total_deals = all_store_products.count
        avg_discount = all_store_products.where('discount > 0').average(:discount)&.round || 0
        top_category = all_store_products
          .where("categories IS NOT NULL AND array_length(categories, 1) > 0")
          .pluck(:categories)
          .flatten
          .tally
          .max_by { |_, v| v }
          &.first || 'General'

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page: page,
            total_count: total,
            total_pages: (total.to_f / PER_PAGE).ceil,
            show_next_page: offset + PER_PAGE < total
          },
          store_stats: {
            total_deals:   total_deals,
            avg_discount:  avg_discount,
            top_category:  top_category,
            health_status: CrawlLog.where(store: store_name).order(crawled_at: :desc).first&.health_status || 'unknown'
          }
        }
      end

      def freshness
        store_name = URI.decode_www_form_component(params[:name])

        cache_key = "store_freshness_v1_#{store_name}"
        data = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
          last_log = CrawlLog.where(store: store_name).order(crawled_at: :desc).first

          last_crawled_at = last_log&.crawled_at

          products_added_today = Product.where(store: store_name)
                                        .where('created_at >= ?', Time.current.beginning_of_day)
                                        .count

          avg_age_result = Product.where(store: store_name, expired: false)
                                  .average('EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600')
          avg_deal_age_hours = avg_age_result&.to_f&.round(1) || 0.0

          hours_since_crawl = last_crawled_at ? ((Time.current - last_crawled_at) / 3600.0).round(1) : nil

          freshness_grade = if hours_since_crawl.nil?
            'D'
          elsif hours_since_crawl < 3 && products_added_today > 5
            'A'
          elsif hours_since_crawl < 6
            'B'
          elsif hours_since_crawl < 24
            'C'
          else
            'D'
          end

          {
            last_crawled_at:      last_crawled_at&.iso8601,
            products_added_today: products_added_today,
            avg_deal_age_hours:   avg_deal_age_hours,
            freshness_grade:      freshness_grade,
            hours_since_crawl:    hours_since_crawl
          }
        end

        render json: data
      end
    end
  end
end
