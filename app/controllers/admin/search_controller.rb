# frozen_string_literal: true

module Admin
  class SearchController < BaseController
    def index
      q = params[:q].to_s.strip

      if q.blank?
        @results = { products: [], subscribers: [], coupons: [] }
        respond_to do |fmt|
          fmt.html
          fmt.json { render json: @results }
        end
        return
      end

      wildcard = "%#{q.downcase}%"

      products = Product.where(
        'LOWER(name) LIKE ? OR LOWER(store) LIKE ?', wildcard, wildcard
      ).order(updated_at: :desc).limit(5)

      subscribers = Subscriber.where(
        'LOWER(email) LIKE ?', wildcard
      ).order(created_at: :desc).limit(5)

      coupons = Coupon.where(
        'LOWER(code) LIKE ? OR LOWER(store) LIKE ?', wildcard, wildcard
      ).order(created_at: :desc).limit(5)

      @results = {
        products:    products.map { |p| { id: p.id, name: p.name, store: p.store, price: p.price } },
        subscribers: subscribers.map { |s| { id: s.id, email: s.email, status: s.status } },
        coupons:     coupons.map { |c| { id: c.id, code: c.code, store: c.store, expires_at: c.expires_at } }
      }

      respond_to do |fmt|
        fmt.html
        fmt.json { render json: @results }
      end
    end
  end
end
