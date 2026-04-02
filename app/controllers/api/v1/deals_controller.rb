module Api
  module V1
    class DealsController < ApplicationController
      include ActionController::Live
      def index
        response.set_header('Cache-Control', 'public, max-age=60')

        if params[:query].blank? && params[:stores].blank? && params[:categories].blank?
          cache_key = "deals_index_v2_p#{params[:page]||1}_pp#{params[:per_page]||20}_#{(params[:order]||{}).to_json}"
          cached = Rails.cache.fetch(cache_key, expires_in: 3.minutes) do
            service = Deals::Index.call(params)
            { products: service.paginate.collection.map { |p| select_fields(p.as_json) },
              metadata: service.paginate.metadata }
          end
          render json: cached and return
        end

        service = Deals::Index.call(params)
        currency = params[:currency].presence

        render json: {
          products: service.paginate.collection.map { |p| select_fields(p.as_json(currency: currency)) },
          metadata: service.paginate.metadata
        }
      end

      def price_watch
        currency = params[:currency].presence
        products = Product.where(expired: false)
                          .joins(:price_alerts)
                          .where(price_alerts: { status: 'active' })
                          .group('products.id')
                          .order(Arel.sql('COUNT(price_alerts.id) DESC'))
                          .limit(20)
                          .select('products.*, COUNT(price_alerts.id) AS watcher_count')

        render json: {
          products: products.map do |p|
            p.as_json(currency: currency).merge('watcher_count' => p.watcher_count.to_i)
          end
        }
      end

      def bundles
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page
        currency = params[:currency].presence

        store_filter = params[:store].presence
        base = Product.where(expired: false)
                      .where(is_bundle: true)
                      .order(deal_score: :desc, created_at: :desc)
        base = base.where(store: store_filter) if store_filter

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map { |p| p.as_json(currency: currency) },
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def featured
        products = Product.includes(:ai_deal_analysis)
                          .where(featured: true, expired: false)
                          .order(updated_at: :desc)
                          .limit(10)
        render json: { products: products }
      end

      def personalised
        stores     = Array(params[:stores]).first(5).map(&:to_s)
        categories = Array(params[:categories]).first(5).map(&:to_s)

        products = Product.includes(:ai_deal_analysis).where(expired: false)

        if stores.any? || categories.any?
          store_scope    = stores.any?     ? Product.where(store: stores)                                              : Product.none
          category_scope = categories.any? ? Product.where('categories && array[?]::varchar[]', categories)           : Product.none
          products = products.merge(store_scope.or(category_scope))
        end

        products = products.where('discount > 0')
                           .order(deal_score: :desc, discount: :desc)
                           .limit(8)

        render json: { products: products }
      end

      def show
        product = Product.find(params[:id])
        response.set_header('Last-Modified', product.updated_at.httpdate)
        response.set_header('Cache-Control', 'public, s-maxage=300, stale-while-revalidate=60')
        if stale?(last_modified: product.updated_at, public: true)
          render json: product
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def engagement
        product = Product.find(params[:id])
        cache_key = "deal_engagement_v1_#{product.id}"
        data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
          views    = product.view_count.to_i
          votes    = product.respond_to?(:upvotes) ? product.upvotes.to_i : 0
          comments = product.respond_to?(:comments_count) ? product.comments_count.to_i : (product.respond_to?(:comment_count) ? product.comment_count.to_i : 0)
          shares   = product.share_count.to_i
          score    = (views * 0.1 + votes * 2 + comments * 3 + shares * 2).round(1)
          { views: views, votes: votes, comments: comments, shares: shares, score: score }
        end
        render json: data
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def recommendations
        product = Product.find(params[:id])
        cache_key = "recommendations_v1_#{product.id}"
        products = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          price_low  = product.price.to_f * 0.7
          price_high = product.price.to_f * 1.3
          tags       = Array(product.tags)

          candidates = Product.where.not(id: product.id).where(expired: false)

          candidates.map do |p|
            weight = 0
            weight += 3 if product.categories.present? && (p.categories & product.categories).any?
            weight += 2 if p.store == product.store
            weight += 1 if tags.any? && (Array(p.tags) & tags).any?
            weight += 1 if p.price.to_f.between?(price_low, price_high)
            [p, weight]
          end
            .select { |_, w| w > 0 }
            .sort_by { |_, w| -w }
            .first(6)
            .map { |p, _| p.as_json }
        end
        render json: { products: products }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def similar
        product = Product.find(params[:id])

        cache_key = "deal_similar_v2_#{product.id}"
        products = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          product_tags = Array(product.tags)
          price = product.price.to_f
          price_low  = price * 0.7
          price_high = price * 1.3

          # Gather candidates - same category or same store
          store_scope    = Product.where(store: product.store)
          category_scope = product.categories.any? ? Product.where('categories && array[?]::varchar[]', product.categories) : Product.none

          candidates = store_scope.or(category_scope)
                                  .where.not(id: product.id)
                                  .where(expired: false)
                                  .limit(200)
                                  .to_a

          # Score each candidate
          scored = candidates.map do |p|
            score = 0
            score += 3 if product.categories.present? && (p.categories & product.categories).any?
            score += 2 if p.store == product.store
            score += 2 if price > 0 && p.price.to_f.between?(price_low, price_high)
            overlapping_tags = product_tags.any? ? (Array(p.tags) & product_tags).size : 0
            score += overlapping_tags
            [p, score]
          end

          scored
            .select { |_, w| w > 0 }
            .sort_by { |_, w| -w }
            .first(8)
            .map { |p, _| p.as_json }
        end

        render json: { products: products }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def top_picks
        products = Rails.cache.fetch('top_picks_v2', expires_in: 15.minutes) do
          Product.where(expired: false)
                 .includes(:ai_deal_analysis, :votes, :click_trackings)
                 .limit(200)
                 .to_a
                 .sort_by { |p| -p.aggregate_score }
                 .first(20)
                 .map(&:as_json)
        end
        render json: { products: products }
      end

      def hot
        products = Rails.cache.fetch('hot_deals_v1', expires_in: 5.minutes) do
          Product.where(expired: false)
                 .includes(:votes, :click_trackings)
                 .map { |p| [p, p.heat_index] }
                 .sort_by { |_, hi| -hi }
                 .first(20)
                 .map { |p, _| p.as_json }
        end
        render json: { products: products }
      end

      def trending
        products = Rails.cache.fetch('trending_deals_v2', expires_in: 10.minutes) do
          since = 24.hours.ago

          view_counts = Product.where(expired: false)
                               .select(:id, :view_count)
                               .index_by(&:id)

          click_counts = ClickTracking.where(clicked_at: since..)
                                      .group(:product_id)
                                      .count

          upvote_counts = Vote.where("value > 0").where(created_at: since..)
                              .group(:product_id)
                              .count

          scored_ids = (click_counts.keys | upvote_counts.keys).uniq
          return [] if scored_ids.empty?

          scored = scored_ids.map do |pid|
            vc = view_counts[pid]&.view_count.to_f
            uc = upvote_counts[pid].to_f
            cc = click_counts[pid].to_f
            score = vc * 0.3 + uc * 0.5 + cc * 0.2
            [pid, score]
          end

          top_ids = scored.sort_by { |_, s| -s }.first(20).map(&:first)
          Product.where(id: top_ids, expired: false).map(&:as_json)
        end

        render json: { products: products }
      end

      def best_drops
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        dropped_ids = PriceHistory
          .where('recorded_at >= ?', 24.hours.ago)
          .where('old_price > price')
          .distinct
          .pluck(:product_id)

        base = Product
          .where(id: dropped_ids, expired: false)
          .where('discount > 0')
          .order(discount: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def new_today
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('products.created_at >= ?', 24.hours.ago)
          .order(created_at: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def fresh
        response.set_header('Cache-Control', 'no-store')
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('products.created_at >= ?', 2.hours.ago)
          .order(created_at: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def expiring_soon
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('expires_at IS NOT NULL AND expires_at > ? AND expires_at <= ?', Time.current, 48.hours.from_now)
          .order(expires_at: :asc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def this_week
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('products.created_at >= ?', 7.days.ago)
          .order(deal_score: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def deal_of_the_week
        aest_week = Time.current.in_time_zone('Australia/Sydney').to_date.beginning_of_week

        deal = Rails.cache.fetch("deal_of_the_week_#{aest_week}", expires_in: 8.days) do
          candidates = Product.where(expired: false)
                               .where('products.created_at >= ?', 7.days.ago)
                               .where.not(image_url: [nil, ''])
                               .order(deal_score: :desc)
                               .limit(10)
                               .to_a

          candidates[aest_week.cweek % [candidates.size, 1].max]
        end

        if deal
          render json: deal.as_json
        else
          render json: nil
        end
      end

      def deal_of_the_day
        # Use AEST date so it rotates at midnight Australian time
        aest_today = Time.current.in_time_zone('Australia/Sydney').to_date

        deal = Rails.cache.fetch("deal_of_the_day_#{aest_today}", expires_in: 25.hours) do
          # Pick from top 20 scored deals, rotate by day-of-year so it changes daily
          candidates = Product.where(expired: false)
                               .where('discount > 20')
                               .where.not(image_url: [nil, ''])
                               .order(deal_score: :desc, discount: :desc)
                               .limit(20)
                               .to_a

          # Deterministically rotate through candidates each day
          candidates[aest_today.yday % [candidates.size, 1].max]
        end

        if deal
          # Save to deal of day history
          DealOfDayHistory.find_or_create_by(date: aest_today) do |h|
            h.product_id = deal.id
          end
          render json: deal.as_json
        else
          render json: nil
        end
      end

      def past_deals_of_day
        histories = DealOfDayHistory.where('date >= ?', 30.days.ago.to_date)
                                    .order(date: :desc)
                                    .limit(30)
        product_ids = histories.pluck(:product_id)
        products = Product.where(id: product_ids).index_by(&:id)

        result = histories.map do |h|
          product = products[h.product_id]
          next unless product
          product.as_json.merge(deal_of_day_date: h.date.to_s)
        end.compact

        render json: { products: result }
      end

      def flash_deals
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product.where(flash_deal: true, expired: false)
                      .where('flash_expires_at > ?', Time.current)
                      .order(flash_expires_at: :asc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def compare
        ids = Array(params[:ids]).first(4).map(&:to_i)
        products = Product.where(id: ids)
        winner = products.max_by { |p| p.deal_score.to_i }
        render json: {
          products: products.map(&:as_json),
          winner_id: winner&.id
        }
      end

      VIEW_MILESTONES = [100, 500, 1000, 5000].freeze

      def view
        product = Product.find(params[:id])
        old_count = product.view_count.to_i
        Product.update_counters(product.id, view_count: 1)
        new_count = old_count + 1

        # Check for view milestones
        milestone = VIEW_MILESTONES.find { |m| old_count < m && new_count >= m }
        if milestone
          NotificationLog.create!(
            notification_type: 'view_milestone',
            recipient: "product:#{product.id}",
            subject: "#{product.name} reached #{milestone} views",
            status: 'sent'
          )
          WebhookDispatcher.dispatch('deal.trending', {
            event: 'deal.trending',
            product_id: product.id,
            product_name: product.name,
            milestone: milestone,
            view_count: new_count,
            triggered_at: Time.current.iso8601
          })
        end

        render json: { ok: true, view_count: new_count }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def report
        product = Product.find(params[:id])
        reason  = params[:reason].to_s
        valid_reasons = %w[expired wrong_price spam broken_link]

        unless valid_reasons.include?(reason)
          return render json: { error: "Invalid reason" }, status: :unprocessable_entity
        end

        DealReport.create!(product: product, reason: reason, session_id: params[:session_id])
        report_count = product.deal_reports.count
        render json: { ok: true, report_count: report_count }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Deal not found' }, status: :not_found
      end

      def recommended
        session_id = params[:session_id].to_s
        prefs = begin
          JSON.parse(params[:preferences].to_s)
        rescue
          {}
        end

        categories  = Array(prefs['categories']).map(&:to_s).first(10)
        stores      = Array(prefs['stores']).map(&:to_s).first(10)
        price_range = Array(prefs['price_range'])
        min_price   = price_range[0].to_f
        max_price   = price_range[1].to_f

        # Factor in voted deals
        voted_product_ids = Vote.where(session_id: session_id).pluck(:product_id) if session_id.present?
        voted_product_ids ||= []
        if voted_product_ids.any?
          voted_products = Product.where(id: voted_product_ids).select(:categories, :store)
          voted_categories = voted_products.flat_map { |p| Array(p.categories) }.uniq.first(5)
          voted_stores = voted_products.map(&:store).compact.uniq.first(5)
          categories = (categories + voted_categories).uniq.first(10)
          stores = (stores + voted_stores).uniq.first(10)
        end

        # Factor in comparison history
        comparison_product_ids = []
        if session_id.present?
          cs = ComparisonSession.where(session_id: session_id).order(created_at: :desc).first
          comparison_product_ids = Array(cs&.product_ids).map(&:to_i)
        end
        if comparison_product_ids.any?
          compared_products = Product.where(id: comparison_product_ids).select(:categories, :store)
          comp_categories = compared_products.flat_map { |p| Array(p.categories) }.uniq.first(5)
          comp_stores = compared_products.map(&:store).compact.uniq.first(5)
          categories = (categories + comp_categories).uniq.first(10)
          stores = (stores + comp_stores).uniq.first(10)
        end

        # Exclude already saved
        saved_ids = []
        if session_id.present?
          saved_ids = SavedDeal.where(session_id: session_id).pluck(:product_id)
        end

        if categories.empty? && stores.empty?
          raw_products = Product.where(expired: false)
                                .where.not(id: saved_ids)
                                .order(deal_score: :desc)
                                .limit(60)
          tuples = raw_products.map { |p| [p, 5, 'Top deals for you'] }
          diverse = apply_recommendation_diversity(tuples)
          return render json: {
            products: diverse.map { |p, score, reason|
              p.as_json.merge('match_reason' => reason, 'match_score' => [[score, 10].min, 0].max)
            }
          }
        end

        all = Product.where(expired: false)
                     .where.not(id: saved_ids)
                     .limit(300)
                     .order(deal_score: :desc)

        scored = all.map do |p|
          score = 0
          reasons = []

          cat_match = categories.any? && (Array(p.categories) & categories).any?
          if cat_match
            score += 3
            matched_cat = (Array(p.categories) & categories).first
            reasons << "Because you like #{matched_cat} deals"
          end

          store_match = stores.any? && stores.include?(p.store)
          if store_match
            score += 2
            reasons << "Because you saved #{p.store} deals"
          end

          if voted_product_ids.any? && cat_match
            score += 1
            reasons << 'Similar to deals you voted on'
          end

          if max_price > 0 && p.price
            if p.price >= min_price && p.price <= max_price
              score += 1
              reasons << "Matches your $#{min_price.to_i}-$#{max_price.to_i} budget"
            end
          end

          reason = reasons.first || 'Recommended for you'
          [p, score, reason]
        end

        top_scored = scored.select { |_, s, _| s > 0 }.sort_by { |_, s, _| -s }.first(60)
        diverse = apply_recommendation_diversity(top_scored)
        render json: {
          products: diverse.map { |p, score, reason|
            match_score = [[score, 10].min, 0].max
            p.as_json.merge('match_reason' => reason, 'match_score' => match_score)
          }
        }
      end

      def ai_summary
        product = Product.find(params[:id])
        analysis = product.ai_deal_analysis

        if analysis&.fresh?
          recommendation = analysis.recommendation
          reasoning      = analysis.reasoning
          confidence     = analysis.confidence&.downcase || 'medium'
        else
          discount = product.discount.to_f
          if discount > 50
            recommendation = 'BUY_NOW'
            reasoning      = 'Exceptional deal — over 50% off. Buy now.'
            confidence     = 'high'
          elsif discount >= 25
            recommendation = 'GOOD_DEAL'
            reasoning      = 'Good deal. Price is well below RRP.'
            confidence     = 'medium'
          else
            recommendation = 'WAIT'
            reasoning      = 'Modest discount. Compare before buying.'
            confidence     = 'low'
          end
        end

        # Price context: lowest in 30 days
        recent_prices = product.price_histories.where('recorded_at >= ?', 30.days.ago).pluck(:price)
        price_context = if recent_prices.any? && product.price.to_f < recent_prices.min.to_f
                          'Lowest price in 30 days'
                        else
                          nil
                        end

        render json: {
          recommendation: recommendation,
          reasoning:      reasoning,
          confidence:     confidence,
          price_context:  price_context
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def share
        product = Product.find(params[:id])
        platform = params[:platform].presence || params[:share_type].presence || 'unknown'
        platform = platform.to_s.downcase.gsub(/[^a-z0-9_]/, '_')

        product.with_lock do
          product.increment!(:share_count)
          breakdown = product.share_breakdown || {}
          breakdown[platform] = (breakdown[platform] || 0) + 1
          product.update_column(:share_breakdown, breakdown)
        end

        render json: { ok: true, share_count: product.share_count }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def shares
        product = Product.find(params[:id])
        breakdown = product.share_breakdown || {}
        total = product.share_count.to_i

        by_platform = breakdown.map do |platform, count|
          pct = total > 0 ? (count.to_f / total * 100).round(1) : 0.0
          { platform: platform, count: count, percent: pct }
        end.sort_by { |r| -r[:count] }

        render json: { total: total, breakdown: by_platform }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def alert_suggestions
        product = Product.find(params[:id])
        current_price = product.price.to_f

        prices = product.price_histories.pluck(:price).map(&:to_f).reject { |p| p <= 0 }
        historical_low = prices.min || current_price
        all_time_low   = prices.min || current_price

        low_seen_count = prices.count { |p| p <= historical_low * 1.01 }

        render json: {
          current_price:  current_price,
          suggestions: [
            {
              label:      'Historical Low',
              price:      historical_low.round(2),
              confidence: "This price has been seen #{low_seen_count} time#{low_seen_count == 1 ? '' : 's'}"
            },
            {
              label:      '10% drop',
              price:      (current_price * 0.9).round(2),
              confidence: nil
            },
            {
              label:      '20% drop',
              price:      (current_price * 0.8).round(2),
              confidence: nil
            },
            {
              label:      'All-time Low',
              price:      all_time_low.round(2),
              confidence: "Absolute minimum ever tracked"
            }
          ]
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def price_analytics
        product = Product.find(params[:id])
        records = product.price_histories.order(recorded_at: :desc).limit(100).pluck(:price).map(&:to_f).reject { |p| p <= 0 }

        if records.empty?
          return render json: {
            avg_price: product.price.to_f,
            min_price: product.price.to_f,
            max_price: product.price.to_f,
            price_volatility: 0.0,
            trend: 'stable',
            total_records: 0
          }
        end

        avg = records.sum / records.size
        min_price = records.min
        max_price = records.max

        variance = records.sum { |p| (p - avg)**2 } / records.size
        std_dev = Math.sqrt(variance)
        volatility = avg > 0 ? (std_dev / avg).round(4) : 0.0

        last10 = records.first(10).reverse
        trend = if last10.size >= 3
          n = last10.size.to_f
          x_mean = (n - 1) / 2.0
          y_mean = last10.sum / n
          numerator = last10.each_with_index.sum { |y, i| (i - x_mean) * (y - y_mean) }
          denominator = last10.each_with_index.sum { |_, i| (i - x_mean)**2 }
          slope = denominator > 0 ? numerator / denominator : 0.0
          threshold = avg * 0.01
          if slope > threshold
            'rising'
          elsif slope < -threshold
            'falling'
          else
            'stable'
          end
        else
          'stable'
        end

        render json: {
          avg_price: avg.round(2),
          min_price: min_price.round(2),
          max_price: max_price.round(2),
          price_volatility: volatility,
          trend: trend,
          total_records: records.size
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def price_prediction
        product = Product.find(params[:id])

        histories = product.price_histories
                           .order(recorded_at: :asc)
                           .limit(30)
                           .to_a

        current_price = product.price.to_f

        if histories.size < 2
          return render json: {
            prediction:             'STABLE',
            confidence:             'low',
            reasoning:              'Not enough price history to make a prediction.',
            predicted_price_7d:     nil,
            predicted_direction:    'stable'
          }
        end

        prices = histories.map { |h| h.price.to_f }
        oldest_price = prices.first

        predicted_price_7d = nil
        predicted_direction = 'stable'

        # Linear regression if 5+ records
        if histories.size >= 5
          n = prices.size.to_f
          x_mean = (n - 1) / 2.0
          y_mean = prices.sum / n

          numerator   = prices.each_with_index.sum { |y, i| (i - x_mean) * (y - y_mean) }
          denominator = prices.each_with_index.sum { |_, i| (i - x_mean) ** 2 }
          slope = denominator > 0 ? numerator / denominator : 0.0

          # Estimate days between records
          if histories.size >= 2
            total_span = (histories.last.recorded_at - histories.first.recorded_at).to_f / 86400.0
            days_per_step = total_span / (histories.size - 1).to_f
          else
            days_per_step = 1.0
          end

          steps_7d = days_per_step > 0 ? (7.0 / days_per_step).round : 7
          raw_predicted = current_price + slope * steps_7d
          predicted_price_7d = [raw_predicted, 0.01].max.round(2)

          threshold = current_price * 0.02
          if raw_predicted - current_price > threshold
            predicted_direction = 'rising'
          elsif current_price - raw_predicted > threshold
            predicted_direction = 'falling'
          else
            predicted_direction = 'stable'
          end
        else
          # Fall back to rule-based when fewer than 5 records
          recent3 = prices.last(3)
          prices_dropping = recent3.each_cons(2).all? { |a, b| a >= b }
          prices_rising   = recent3.each_cons(2).all? { |a, b| a <= b }
          predicted_direction = if prices_rising then 'rising'
                                elsif prices_dropping then 'falling'
                                else 'stable'
                                end
        end

        # Check if price has been the same for 7+ days
        seven_days_ago = 7.days.ago
        old_history = product.price_histories
                             .where('recorded_at <= ?', seven_days_ago)
                             .order(recorded_at: :desc)
                             .limit(1)
                             .first

        if old_history && (old_history.price.to_f - current_price).abs < 0.01 && histories.size >= 3
          return render json: {
            prediction:          'STABLE',
            confidence:          'high',
            reasoning:           'Price has been unchanged for 7+ days. Safe to buy at this price.',
            predicted_price_7d:  predicted_price_7d,
            predicted_direction: 'stable'
          }
        end

        # Rule-based decisions
        recent3 = prices.last(3)
        prices_dropped = recent3.each_cons(2).all? { |a, b| a >= b }

        if prices_dropped && recent3.size >= 3
          return render json: {
            prediction:          'HOLD',
            confidence:          'medium',
            reasoning:           'Price has been dropping recently - it may drop further. Consider waiting.',
            predicted_price_7d:  predicted_price_7d,
            predicted_direction: predicted_direction
          }
        end

        if current_price < prices.min + 0.01 || (oldest_price > current_price * 1.1)
          return render json: {
            prediction:          'BUY_NOW',
            confidence:          'high',
            reasoning:           "Price is at its lowest recorded level (was $#{oldest_price.round(2)}). Great time to buy!",
            predicted_price_7d:  predicted_price_7d,
            predicted_direction: predicted_direction
          }
        end

        render json: {
          prediction:          'STABLE',
          confidence:          'medium',
          reasoning:           'Price is relatively stable. No strong signal to wait or rush.',
          predicted_price_7d:  predicted_price_7d,
          predicted_direction: predicted_direction
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def expiry_prediction
        product = Product.find(params[:id])
        name_lower = product.name.to_s.downcase

        if product.respond_to?(:flash_deal) && product.flash_deal
          days = 1
          confidence = 'high'
          reason = 'Flash deals typically expire within 24 hours.'
        elsif name_lower.include?('clearance')
          days = 14
          confidence = 'medium'
          reason = 'Clearance items typically last around 14 days.'
        elsif name_lower.include?('sale') || (product.respond_to?(:discount) && product.discount.to_f >= 20)
          days = 7
          confidence = 'medium'
          reason = 'Sale items average about 7 days before expiring.'
        else
          avg_lifespan = Product.where(store: product.store)
                                .where.not(expired: false)
                                .where('created_at > ?', 90.days.ago)
                                .average('EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400')
          days = avg_lifespan ? avg_lifespan.to_i.clamp(3, 30) : 7
          confidence = avg_lifespan ? 'medium' : 'low'
          reason = avg_lifespan ? "Based on average deal lifespan from #{product.store}." : 'Estimated based on typical deal duration.'
        end

        predicted_expiry = product.created_at + days.days
        elapsed_days = ((Time.current - product.created_at) / 86400).to_i
        remaining_days = [days - elapsed_days, 0].max

        render json: {
          predicted_expiry: predicted_expiry.iso8601,
          remaining_days:   remaining_days,
          confidence:       confidence,
          reason:           reason
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def meta
        product = Product.find(params[:id])
        meta_data = Rails.cache.fetch("deal_meta_#{product.id}", expires_in: 5.minutes) do
          availability = product.expired? ? 'OutOfStock' : 'InStock'
          image = product.image_urls&.first || product.image_url
          {
            title: "#{product.name} - $#{product.price} at #{product.store} | OzVFY",
            description: product.description.presence || "#{product.name} now $#{product.price}#{product.old_price ? " (was $#{product.old_price})" : ''} at #{product.store}. #{product.discount}% off!",
            og_image: image,
            canonical_url: "https://www.ozvfy.com/deals/#{product.id}",
            price: product.price,
            currency: product.currency.presence || 'AUD',
            availability: availability
          }
        end
        render json: meta_data
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def most_shared
        products = Product.where('share_count > 0').order(share_count: :desc).limit(20)
        render json: { products: products.map(&:as_json) }
      end

      def redirect
        product = Product.find(params[:id])

        utm_params = ClickTracking.utm_from_url(request.referer)
        ClickTracking.create!(
          product_id: product.id,
          store: product.store,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          referrer: request.referer,
          clicked_at: Time.current,
          utm_source:   params[:utm_source].presence || utm_params[:utm_source],
          utm_medium:   params[:utm_medium].presence || utm_params[:utm_medium],
          utm_campaign: params[:utm_campaign].presence || utm_params[:utm_campaign]
        )

        affiliate_url = AffiliateUrlService.call(product)

        # Track revenue event: 5% commission, 2% conversion rate
        estimated_value = (product.price.to_f * 0.05 * 0.02).round(4)
        RevenueEvent.create!(
          product_id: product.id,
          click_id: SecureRandom.uuid,
          estimated_value: estimated_value,
          store: product.store
        )

        render json: {
          affiliate_url: affiliate_url,
          click_count: product.click_count
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end

      def popular
        products = Rails.cache.fetch('popular_deals_v1', expires_in: 15.minutes) do
          Product.where(expired: false)
                 .order(updated_at: :desc)
                 .limit(200)
                 .to_a
                 .sort_by { |p| -p.popularity_score }
                 .first(20)
        end
        render json: { products: products.map(&:as_json) }
      end

      def high_quality
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        # Load candidates and filter by quality_score in Ruby (computed attribute)
        candidates = Product.where(expired: false)
                            .order(deal_score: :desc, created_at: :desc)
                            .limit(500)
                            .to_a
                            .select { |p| p.quality_score >= 70 }

        total    = candidates.size
        products = candidates[offset, per_page] || []

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def deal_of_the_month
        year  = Date.today.year
        month = Date.today.month
        cache_key = "deal_of_month_#{year}_#{month}"

        deal = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
          Product.where(expired: false)
                 .where('products.created_at >= ?', Date.today.beginning_of_month)
                 .where('discount > 0')
                 .where.not(image_url: [nil, ''])
                 .select('products.*, (discount * view_count * GREATEST(1, (SELECT COUNT(*) FROM votes WHERE votes.product_id = products.id AND value = 1))) AS month_score')
                 .order('month_score DESC NULLS LAST, deal_score DESC')
                 .first
        end

        if deal
          render json: deal.as_json
        else
          render json: nil
        end
      end

      def biggest_drops
        cache_key = 'biggest_drops_v1'
        result = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          rows = Product
            .joins(:price_histories)
            .where(expired: false)
            .where('price_histories.old_price IS NOT NULL AND price_histories.old_price > products.price')
            .select(
              'products.*',
              'MAX(price_histories.old_price) AS old_price_hist',
              'MAX(price_histories.old_price) - MIN(products.price) AS absolute_drop',
              'ROUND(((MAX(price_histories.old_price) - MIN(products.price)) / NULLIF(MAX(price_histories.old_price), 0) * 100)::numeric, 1) AS drop_percent'
            )
            .group('products.id')
            .order('absolute_drop DESC NULLS LAST')
            .limit(20)

          rows.map do |p|
            p.as_json.merge(
              'absolute_drop' => p.attributes['absolute_drop'].to_f.round(2),
              'drop_percent'  => p.attributes['drop_percent'].to_f
            )
          end
        end

        render json: { products: result }
      end

      def compare_prices
        query = params[:name].to_s.strip
        if query.blank?
          return render json: { error: 'name param required' }, status: :unprocessable_entity
        end

        results = Product
          .where('name ILIKE ?', "%#{query}%")
          .where(expired: false)
          .order(:price)
          .limit(50)
          .to_a

        # Group by store, keep cheapest per store
        by_store = results.group_by(&:store).transform_values { |prods| prods.min_by { |p| p.price.to_f } }

        comparison = by_store.values.map do |p|
          {
            store:       p.store,
            price:       p.price.to_f,
            old_price:   p.old_price.to_f,
            discount:    p.discount.to_f,
            product_id:  p.id,
            url:         p.store_url
          }
        end.sort_by { |r| r[:price] }

        render json: { comparison: comparison }
      end

      private

      # Enforce diversity: max 3 per store, max 4 per category, price range mix
      # tuples is Array of [product, score, reason]
      def apply_recommendation_diversity(tuples)
        store_counts    = Hash.new(0)
        category_counts = Hash.new(0)
        result          = []

        tuples.each do |p, score, reason|
          next if store_counts[p.store] >= 3
          cats = Array(p.categories)
          next if cats.any? && cats.all? { |c| category_counts[c] >= 4 }

          store_counts[p.store] += 1
          cats.each { |c| category_counts[c] += 1 }
          result << [p, score, reason]
          break if result.size >= 20
        end

        # Ensure price range mix: at least 1 under $50, 1 $50-$200, 1 over $200
        price_buckets = { low: false, mid: false, high: false }
        result.each do |p, _, _|
          pr = p.price.to_f
          if pr < 50
            price_buckets[:low] = true
          elsif pr <= 200
            price_buckets[:mid] = true
          else
            price_buckets[:high] = true
          end
        end

        unless price_buckets[:low]
          candidate = tuples.find { |p, _, _| p.price.to_f < 50 && result.none? { |r, _, _| r.id == p.id } }
          result << candidate if candidate
        end

        unless price_buckets[:mid]
          candidate = tuples.find { |p, _, _| p.price.to_f.between?(50, 200) && result.none? { |r, _, _| r.id == p.id } }
          result << candidate if candidate
        end

        unless price_buckets[:high]
          candidate = tuples.find { |p, _, _| p.price.to_f > 200 && result.none? { |r, _, _| r.id == p.id } }
          result << candidate if candidate
        end

        result.first(20)
      end

      def select_fields(json_hash)
        return json_hash unless params[:fields].present?

        requested = params[:fields].to_s.split(',').map(&:strip).reject(&:blank?)
        return json_hash if requested.empty?

        json_hash.slice(*requested)
      end

      public

      def freshness_stats
        now = Time.current
        base = Product.where(expired: false)

        ultra_fresh = base.where('created_at >= ?', 2.hours.ago).count
        fresh       = base.where('created_at >= ? AND created_at < ?', 24.hours.ago, 2.hours.ago).count
        recent      = base.where('created_at >= ? AND created_at < ?', 3.days.ago, 24.hours.ago).count
        older       = base.where('created_at < ?', 3.days.ago).count

        render json: {
          ultra_fresh: ultra_fresh,
          fresh: fresh,
          recent: recent,
          older: older,
          as_of: now.iso8601
        }
      end

      def live_feed
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['X-Accel-Buffering'] = 'no'
        response.headers['Access-Control-Allow-Origin'] = '*'

        sse = ActionController::Live::SSE.new(response.stream, retry: 3000)

        begin
          deadline = Time.current + 60.seconds
          last_heartbeat = Time.current

          loop do
            break if Time.current >= deadline

            cached_key = "live_feed_latest_#{(Time.current.to_i / 5)}"
            new_deals = Rails.cache.fetch(cached_key, expires_in: 5.seconds) do
              Product.where(expired: false)
                     .where('created_at >= ?', 30.seconds.ago)
                     .order(created_at: :desc)
                     .limit(5)
                     .map { |p| p.as_json }
            end

            if new_deals.any?
              new_deals.each do |deal|
                sse.write(deal.to_json, event: 'new_deal')
              end
            end

            if Time.current - last_heartbeat >= 10.seconds
              sse.write({ type: 'heartbeat', timestamp: Time.current.iso8601 }.to_json, event: 'heartbeat')
              last_heartbeat = Time.current
            end

            sleep 2
          end
        rescue ActionController::Live::ClientDisconnected
          # client disconnected - normal
        rescue StandardError => e
          Rails.logger.error("SSE live_feed error: #{e.message}")
        ensure
          sse.close
        end
      end

      def score_history
        product = Product.find(params[:id])
        histories = product.deal_score_histories
                           .order(recorded_at: :desc)
                           .limit(30)
                           .map { |h| { score: h.score.to_f, recorded_at: h.recorded_at.iso8601 } }

        render json: { score_history: histories.reverse }
      end

      def community_picks
        products = Rails.cache.fetch('community_picks_v1', expires_in: 15.minutes) do
          Product.where(expired: false)
                 .includes(:votes, :comments)
                 .limit(200)
                 .to_a
                 .sort_by { |p| -p.community_score }
                 .first(20)
                 .map(&:as_json)
        end
        render json: { products: products }
      end

      def elasticity
        product = Product.find(params[:id])
        cache_key = "elasticity_v1_#{product.id}"
        data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          histories = product.price_histories.order(recorded_at: :asc).to_a
          current_views = product.view_count.to_i

          if histories.size < 3
            next {
              elastic: false,
              sensitivity: 'low',
              insight: 'Not enough price history to analyse elasticity.'
            }
          end

          # Find major price changes (>5% drop)
          changes = []
          histories.each_cons(2) do |older, newer|
            old_p = older.price.to_f
            new_p = newer.price.to_f
            next if old_p <= 0
            pct_change = (old_p - new_p) / old_p
            next unless pct_change.abs >= 0.05
            changes << { at: newer.recorded_at, pct_change: pct_change }
          end

          if changes.empty?
            next {
              elastic: false,
              sensitivity: 'low',
              insight: 'Price has been stable - no significant changes to analyse.'
            }
          end

          # Use view_count as proxy; more changes means higher engagement sensitivity
          avg_drop = changes.sum { |c| c[:pct_change] } / changes.size
          sensitivity = if changes.size >= 3 && avg_drop > 0.15
            'high'
          elsif changes.size >= 2 || avg_drop > 0.08
            'medium'
          else
            'low'
          end

          elastic = sensitivity != 'low'
          insight = case sensitivity
          when 'high'
            "The community responds strongly to price changes on this deal."
          when 'medium'
            "Moderate price sensitivity - shoppers notice when this deal changes."
          else
            "This deal shows low price sensitivity."
          end

          { elastic: elastic, sensitivity: sensitivity, insight: insight }
        end
        render json: data
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def vpp_compatible
        products = Rails.cache.fetch('vpp_compatible_deals_v1', expires_in: 1.hour) do
          Product.where(expired: false)
                 .where(
                   "LOWER(name) LIKE '%vpp%' OR LOWER(name) LIKE '%virtual power%' OR LOWER(name) LIKE '%energy%' OR " \
                   "EXISTS (SELECT 1 FROM unnest(tags) t WHERE LOWER(t) LIKE '%vpp%' OR LOWER(t) LIKE '%virtual power%' OR LOWER(t) LIKE '%energy%') OR " \
                   "categories && ARRAY['Electronics']::varchar[]"
                 )
                 .order(deal_score: :desc)
                 .limit(50)
                 .map(&:as_json)
        end
        render json: { products: products }
      end

      # GET /api/v1/deals/:id/cluster
      def cluster
        deal = Product.find(params[:id])
        currency = params[:currency].presence

        unless deal.brand.present?
          return render json: { products: [], count: 0, brand: nil }
        end

        min_price = deal.price * 0.8
        max_price = deal.price * 1.2

        cluster_deals = Product
          .where(expired: false)
          .where(brand: deal.brand)
          .where(price: min_price..max_price)
          .where.not(id: deal.id)
          .where.not(store: deal.store)
          .order(deal_score: :desc)
          .limit(10)

        render json: {
          products: cluster_deals.map { |p| p.as_json(currency: currency) },
          count: cluster_deals.size,
          brand: deal.brand
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      # POST /api/v1/deals/:id/funnel
      def funnel
        deal = Product.find(params[:id])
        stage = params[:stage].to_s
        session_id = params[:session_id].to_s

        valid_stages = %w[view click purchase_intent]
        unless valid_stages.include?(stage)
          return render json: { error: "Invalid stage. Must be one of: #{valid_stages.join(', ')}" }, status: :unprocessable_entity
        end

        ClickTracking.create!(
          product_id: deal.id,
          store: deal.store,
          session_id: session_id.presence,
          funnel_stage: stage,
          clicked_at: Time.current,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )

        render json: { ok: true, stage: stage }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      BULK_MAX_IDS = 20

      public

      def bulk_operations
        action      = params[:action_type] || params[:action]
        product_ids = Array(params[:product_ids]).first(BULK_MAX_IDS).map(&:to_i).uniq
        session_id  = params[:session_id].to_s

        if product_ids.empty?
          return render json: { error: 'product_ids required' }, status: :unprocessable_entity
        end

        case action.to_s
        when 'save'
          results = product_ids.map do |pid|
            begin
              product = Product.find(pid)
              SavedDeal.find_or_create_by!(product_id: pid, session_id: session_id) if session_id.present?
              { product_id: pid, success: true }
            rescue ActiveRecord::RecordNotFound
              { product_id: pid, success: false, error: 'Not found' }
            rescue => e
              { product_id: pid, success: false, error: e.message }
            end
          end
          render json: { results: results }

        when 'compare'
          products = Product.where(id: product_ids).limit(4)
          winner = products.max_by { |p| p.deal_score.to_i }
          results = products.map do |p|
            { product_id: p.id, success: true, product: p.as_json }
          end
          render json: { results: results, winner_id: winner&.id }

        when 'price_alert'
          email           = params[:email].to_s.strip
          target_discount = params[:target_discount].to_i

          if email.blank? || email !~ URI::MailTo::EMAIL_REGEXP
            return render json: { error: 'valid email required' }, status: :unprocessable_entity
          end

          results = product_ids.map do |pid|
            begin
              product = Product.find(pid)
              target_price = product.price.to_f * (1 - target_discount / 100.0)
              alert = PriceAlert.create!(
                product_id: pid,
                email: email,
                target_price: [target_price, 0.01].max
              )
              { product_id: pid, success: true, alert_id: alert.id }
            rescue ActiveRecord::RecordNotFound
              { product_id: pid, success: false, error: 'Not found' }
            rescue => e
              { product_id: pid, success: false, error: e.message }
            end
          end
          render json: { results: results }

        else
          render json: { error: "Unknown action: #{action}" }, status: :unprocessable_entity
        end
      end
    end
  end
end
