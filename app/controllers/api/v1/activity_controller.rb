# frozen_string_literal: true

module Api
  module V1
    class ActivityController < ApplicationController
      def index
        page = (params[:page] || 1).to_i
        per_page = 20

        activities = []

        # Price drops (last 48h)
        price_drops = PriceHistory
          .where('recorded_at >= ?', 48.hours.ago)
          .where('old_price > price')
          .includes(:product)
          .order(recorded_at: :desc)
          .limit(50)

        price_drops.each do |ph|
          next unless ph.product
          activities << {
            type: 'price_drop',
            occurred_at: ph.recorded_at || ph.created_at,
            product: ph.product.as_json,
            data: {
              old_price: ph.old_price,
              new_price: ph.price,
              drop_percent: ph.old_price > 0 ? ((ph.old_price - ph.price) / ph.old_price * 100).round(1) : 0
            }
          }
        end

        # New products (last 48h)
        new_products = Product
          .where('created_at >= ?', 48.hours.ago)
          .where(expired: false)
          .order(created_at: :desc)
          .limit(30)

        new_products.each do |p|
          activities << {
            type: 'new_deal',
            occurred_at: p.created_at,
            product: p.as_json,
            data: {}
          }
        end

        # Hot deals (high vote products in last 24h)
        hot_votes = Vote
          .where("value > 0").where(created_at: 24.hours.ago..)
          .group(:product_id)
          .having('count(*) >= 3')
          .count

        if hot_votes.any?
          hot_products = Product.where(id: hot_votes.keys, expired: false)
          hot_products.each do |p|
            activities << {
              type: 'hot_deal',
              occurred_at: p.updated_at,
              product: p.as_json,
              data: { upvotes: hot_votes[p.id] }
            }
          end
        end

        # Sort newest first
        sorted = activities.sort_by { |a| -a[:occurred_at].to_i }
        total = sorted.size
        paginated = sorted[(page - 1) * per_page, per_page] || []

        render json: {
          activities: paginated,
          metadata: {
            page: page,
            per_page: per_page,
            total_count: total,
            show_next_page: page * per_page < total
          }
        }
      end
    end
  end
end
