# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StoreStatsController < ApplicationController
        include AdminAuthentication

        def index
          stats = Product.group(:store).select(
            :store,
            "COUNT(*) AS total_products",
            "COUNT(*) FILTER (WHERE expired = false) AS active_products",
            "COUNT(*) FILTER (WHERE expired = true) AS expired_products",
            "MAX(updated_at) AS last_crawled_at",
            "AVG(discount) FILTER (WHERE expired = false AND discount > 0) AS avg_discount"
          ).map do |row|
            {
              store: row.store,
              total_products: row.total_products,
              active_products: row.active_products,
              expired_products: row.expired_products,
              last_crawled_at: row.last_crawled_at,
              avg_discount: row.avg_discount&.to_f&.round(1)
            }
          end

          render json: { store_stats: stats }
        end
      end
    end
  end
end
