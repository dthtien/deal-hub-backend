# frozen_string_literal: true

module Api
  module V1
    class BrandsController < ApplicationController
      def index
        brands = Rails.cache.fetch('brands_index_v1', expires_in: 30.minutes) do
          Product.where(expired: false)
                 .where.not(brand: [nil, ''])
                 .group(:brand)
                 .select('brand, COUNT(*) AS deal_count, ROUND(AVG(discount), 1) AS avg_discount')
                 .order('deal_count DESC')
                 .limit(20)
                 .map { |r| { brand: r.brand, deal_count: r.deal_count, avg_discount: r.avg_discount.to_f } }
        end
        render json: { brands: brands }
      end

      def deals
        brand_name = params[:name].to_s
        page     = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 25).to_i
        offset   = (page - 1) * per_page

        base = Product.where(expired: false)
                      .where('LOWER(brand) = LOWER(?)', brand_name)
                      .order(deal_score: :desc, created_at: :desc)

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
    end
  end
end
