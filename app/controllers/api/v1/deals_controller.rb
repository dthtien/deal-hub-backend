module Api
  module V1
    class DealsController < ApplicationController
      def index
        response.set_header('Cache-Control', 'public, max-age=60')
        service = Deals::Index.call(params)
        currency = params[:currency].presence

        render json: {
          products: service.paginate.collection.map { |p| p.as_json(currency: currency) },
          metadata: service.paginate.metadata
        }
      end

      def price_watch
        currency = params[:currency].presence
        products = Product.where(expired: false)
                          .joins(:price_alerts)
                          .where(price_alerts: { status: 'active' })
                          .group('products.id')
                          .order('COUNT(price_alerts.id) DESC')
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
        response.set_header('Cache-Control', 'public, max-age=300, stale-while-revalidate=60')
        product = Product.find(params[:id])
        render json: product
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

          upvote_counts = Vote.where(vote_type: 'up', created_at: since..)
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

      def view
        product = Product.find(params[:id])
        Product.update_counters(product.id, view_count: 1)
        render json: { ok: true, view_count: product.view_count + 1 }
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

        if categories.empty? && stores.empty?
          products = Product.where(expired: false)
                            .order(deal_score: :desc)
                            .limit(20)
          return render json: { products: products.map(&:as_json) }
        end

        all = Product.where(expired: false).limit(200).order(deal_score: :desc)

        scored = all.map do |p|
          score = 0
          score += 3 if categories.any? && (Array(p.categories) & categories).any?
          score += 2 if stores.any? && stores.include?(p.store)
          if max_price > 0 && p.price
            score += 1 if p.price >= min_price && p.price <= max_price
          end
          [p, score]
        end

        top = scored.sort_by { |_, s| -s }.first(20).map(&:first)
        render json: { products: top.map(&:as_json) }
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
        product.increment!(:share_count)
        render json: { ok: true, share_count: product.share_count }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def price_prediction
        product = Product.find(params[:id])

        histories = product.price_histories
                           .order(recorded_at: :desc)
                           .limit(10)
                           .to_a

        current_price = product.price.to_f

        if histories.size < 2
          return render json: {
            prediction:  'STABLE',
            confidence:  'low',
            reasoning:   'Not enough price history to make a prediction.'
          }
        end

        recent3  = histories.first(3).map { |h| h.price.to_f }
        all_prices = histories.map { |h| h.price.to_f }
        oldest_price = histories.last.price.to_f

        # Check if price has been the same for 7+ days
        seven_days_ago = 7.days.ago
        old_histories = product.price_histories
                               .where('recorded_at <= ?', seven_days_ago)
                               .order(recorded_at: :desc)
                               .limit(1)
                               .first

        if old_histories && (old_histories.price.to_f - current_price).abs < 0.01 && histories.size >= 3
          return render json: {
            prediction:  'STABLE',
            confidence:  'high',
            reasoning:   'Price has been unchanged for 7+ days. Safe to buy at this price.'
          }
        end

        # Check if price dropped in last 3 histories (rising/stable soon)
        prices_dropped = recent3.each_cons(2).all? { |a, b| a <= b }

        if prices_dropped && recent3.size >= 3
          return render json: {
            prediction:  'HOLD',
            confidence:  'medium',
            reasoning:   'Price has been dropping recently - it may drop further. Consider waiting.'
          }
        end

        # Check if current price is the lowest ever seen
        if current_price < all_prices.min + 0.01 || (oldest_price > current_price * 1.1)
          return render json: {
            prediction:  'BUY_NOW',
            confidence:  'high',
            reasoning:   "Price is at its lowest recorded level (was $#{oldest_price.round(2)}). Great time to buy!"
          }
        end

        render json: {
          prediction:  'STABLE',
          confidence:  'medium',
          reasoning:   'Price is relatively stable. No strong signal to wait or rush.'
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

        ClickTracking.create!(
          product_id: product.id,
          store: product.store,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          referrer: request.referer,
          clicked_at: Time.current
        )

        affiliate_url = AffiliateUrlService.call(product)

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
    end
  end
end
