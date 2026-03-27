# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        response.set_header('Cache-Control', 'public, max-age=3600')
        categories = Product.where(expired: false).pluck('DISTINCT(categories)').flatten.uniq.compact.sort
        render json: { categories: categories }
      end

      def top_deals
        category = CGI.unescape(params[:name].to_s)

        products = Rails.cache.fetch("category_top_deals_#{category}", expires_in: 1.hour) do
          Product.where('categories @> ARRAY[?]::varchar[]', category)
                 .where(expired: false)
                 .order(deal_score: :desc)
                 .limit(10)
                 .map(&:as_json)
        end

        render json: { products: products }
      end
    end
  end
end
