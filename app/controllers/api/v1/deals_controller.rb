module Api
  module V1
    class DealsController < ApplicationController
      def index
        service = Deals::Index.call(params)

        render json: {
          products: service.paginate.collection,
          metadata: service.paginate.metadata
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
        render json: product
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def similar
        product = Product.find(params[:id])
        store_scope    = Product.where(store: product.store)
        category_scope = product.categories.any? ? Product.where('categories && array[?]::varchar[]', product.categories) : Product.none
        similar = store_scope.or(category_scope)
                             .where.not(id: product.id)
                             .where(expired: false)
                             .order(deal_score: :desc)
                             .limit(8)
        render json: { products: similar }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
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
          render json: deal.as_json
        else
          render json: nil
        end
      end

      def flash_deals
        products = Product.where(flash_deal: true, expired: false)
                          .where('flash_expires_at > ?', Time.current)
                          .order(flash_expires_at: :asc)
        render json: { products: products.map(&:as_json) }
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
    end
  end
end
