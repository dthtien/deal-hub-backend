# frozen_string_literal: true

require 'csv'

module Admin
  class ExportsController < BaseController
    def products
      data = CSV.generate(headers: true) do |csv|
        csv << %w[id name store price old_price discount expired created_at]
        Product.where(expired: false).find_each do |p|
          csv << [p.id, p.name, p.store, p.price, p.old_price, p.discount, p.expired, p.created_at]
        end
      end
      send_data data, filename: "products-#{Date.today}.csv", type: 'text/csv', disposition: 'attachment'
    end

    def subscribers
      data = CSV.generate(headers: true) do |csv|
        csv << %w[id email status created_at]
        Subscriber.active.find_each do |s|
          csv << [s.id, s.email, s.status, s.created_at]
        end
      end
      send_data data, filename: "subscribers-#{Date.today}.csv", type: 'text/csv', disposition: 'attachment'
    end

    def coupons
      data = CSV.generate(headers: true) do |csv|
        csv << %w[id store code discount_type discount_value expires_at verified created_at]
        Coupon.active.find_each do |c|
          csv << [c.id, c.store, c.code, c.discount_type, c.discount_value, c.expires_at, c.verified, c.created_at]
        end
      end
      send_data data, filename: "coupons-#{Date.today}.csv", type: 'text/csv', disposition: 'attachment'
    end
  end
end
