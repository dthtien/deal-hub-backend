# frozen_string_literal: true

module Api
  module V1
    class FeedController < ApplicationController
      # GET /api/v1/feed?session_id=X&page=1
      def personalised
        page     = (params[:page] || 1).to_i
        per_page = 20
        session_id = params[:session_id].to_s
        currency = params[:currency].presence

        # Parse stored preferences (stored as JSON by FE)
        prefs = begin
          raw = params[:preferences].presence
          raw ? JSON.parse(raw) : {}
        rescue JSON::ParserError
          {}
        end

        pref_stores     = Array(prefs['stores']).first(5).map(&:to_s).select(&:present?)
        pref_categories = Array(prefs['categories']).first(5).map(&:to_s).select(&:present?)

        # 40% matched, 20% trending, 20% new, 10% flash, 10% community
        counts = {
          matched:   (per_page * 0.40).ceil,
          trending:  (per_page * 0.20).ceil,
          new:       (per_page * 0.20).ceil,
          flash:     (per_page * 0.10).ceil,
          community: (per_page * 0.10).ceil
        }

        base = Product.where(expired: false)

        # 40% — preference-matched
        matched = if pref_stores.any? || pref_categories.any?
          store_scope    = pref_stores.any?     ? base.where(store: pref_stores) : Product.none
          cat_scope      = pref_categories.any? ? base.where('categories && array[?]::varchar[]', pref_categories) : Product.none
          base.merge(store_scope.or(cat_scope))
              .order(deal_score: :desc)
              .limit(counts[:matched])
        else
          base.order(deal_score: :desc).limit(counts[:matched])
        end

        # 20% — trending (high click_count recent)
        trending = base
          .joins(:click_trackings)
          .where(click_trackings: { clicked_at: 48.hours.ago.. })
          .group('products.id')
          .order('COUNT(click_trackings.id) DESC')
          .limit(counts[:trending])

        # 20% — new arrivals
        new_arrivals = base
          .order(created_at: :desc)
          .limit(counts[:new])

        # 10% — flash deals
        flash_deals = base
          .where(flash_deal: true)
          .order(deal_score: :desc)
          .limit(counts[:flash])

        # 10% — community picks (most votes / comments recent)
        community = base
          .joins(:votes)
          .where(votes: { created_at: 7.days.ago.. })
          .group('products.id')
          .order('COUNT(votes.id) DESC')
          .limit(counts[:community])
          .select('products.*')

        # Merge, deduplicate, label
        all_items = []
        seen = Set.new

        add_with_label = lambda do |products, label|
          Array(products).each do |p|
            next if seen.include?(p.id)
            seen.add(p.id)
            all_items << { product: p, label: label }
          end
        end

        add_with_label.call(matched,      'picked')
        add_with_label.call(trending,     'trending')
        add_with_label.call(new_arrivals, 'new')
        add_with_label.call(flash_deals,  'flash')
        add_with_label.call(community,    'community')

        # Fill remaining slots from best deals if short
        if all_items.size < per_page
          fill = base
            .where.not(id: seen.to_a)
            .order(deal_score: :desc)
            .limit(per_page - all_items.size)
          fill.each { |p| all_items << { product: p, label: 'picked' } }
        end

        # Pagination
        total  = all_items.size
        offset = (page - 1) * per_page
        page_items = all_items[offset, per_page] || []

        products_json = page_items.map do |item|
          item[:product].as_json(currency: currency).merge('feed_label' => item[:label])
        end

        render json: {
          products: products_json,
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    [(total.to_f / per_page).ceil, 1].max,
            show_next_page: offset + per_page < total
          }
        }
      end
    end
  end
end
