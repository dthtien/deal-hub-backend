# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
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

      render :index
    end
  end
end
