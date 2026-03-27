module Api
  module V1
    class SearchController < ApplicationController
      def suggestions
        q = params[:q].to_s.strip
        if q.length < 2
          return render json: { deals: [], stores: [], categories: [] }
        end

        deals = Product.where("name ILIKE ?", "%#{q}%")
                       .limit(5)
                       .select(:id, :name, :price, :store, :image_url, :discount)

        stores = Product.where("store ILIKE ?", "%#{q}%")
                        .distinct
                        .limit(3)
                        .pluck(:store)
                        .compact

        all_categories = Product.distinct.pluck(:categories).flatten.compact.uniq
        categories = all_categories.select { |c| c.downcase.include?(q.downcase) }.first(3)

        render json: {
          deals: deals.map { |d| { id: d.id, name: d.name, price: d.price, store: d.store, image_url: d.image_url, discount: d.discount } },
          stores: stores,
          categories: categories
        }
      end

      def track
        query = params[:query].to_s.strip
        result_count = params[:result_count].to_i
        clicked_product_id = params[:clicked_product_id]

        if query.length >= 2
          SearchQuery.track(query, result_count: result_count)
        end

        render json: { ok: true }
      end

      def analytics
        unless current_user&.admin?
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        queries = SearchQuery.order(count: :desc).limit(50)

        render json: queries.map { |q|
          {
            query: q.query,
            count: q.count,
            avg_result_count: q.avg_result_count
          }
        }
      end
    end
  end
end
