# frozen_string_literal: true

module Admin
  class ReportsController < BaseController
    def deal_performance
      page     = (params[:page] || 1).to_i
      per_page = 25
      offset   = (page - 1) * per_page

      sort_col = %w[view_count click_count save_count vote_count comment_count share_count ctr conversion_rate].include?(params[:sort]) ? params[:sort] : 'view_count'
      sort_dir = params[:dir] == 'asc' ? 'asc' : 'desc'

      products = Product.where(expired: false)
                        .order(created_at: :desc)
                        .limit(1000)
                        .to_a

      rows = products.map do |p|
        views    = p.view_count.to_i
        clicks   = p.click_count.to_i
        saves    = SavedDeal.where(product_id: p.id).count
        votes    = p.votes.count
        comments = p.comments.count
        shares   = p.share_count.to_i
        ctr      = views > 0 ? (clicks.to_f / views * 100).round(2) : 0.0
        conv     = (clicks.to_f * 0.05).round(2)

        {
          id:              p.id,
          name:            p.name,
          store:           p.store,
          price:           p.price.to_f,
          discount:        p.discount.to_f,
          view_count:      views,
          click_count:     clicks,
          save_count:      saves,
          vote_count:      votes,
          comment_count:   comments,
          share_count:     shares,
          ctr:             ctr,
          conversion_rate: conv,
          time_on_page:    'N/A'
        }
      end

      rows.sort_by! { |r| r[sort_col.to_sym] || 0 }
      rows.reverse! if sort_dir == 'desc'

      total     = rows.size
      paginated = rows[offset, per_page] || []

      render json: {
        deals: paginated,
        metadata: {
          page: page,
          per_page: per_page,
          total_count: total,
          total_pages: (total.to_f / per_page).ceil,
          sort: sort_col,
          dir: sort_dir
        }
      }
    end

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
