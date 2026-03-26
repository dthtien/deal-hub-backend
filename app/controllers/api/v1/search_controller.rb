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

        # Get categories from metadata and filter
        all_categories = Product.distinct.pluck(:categories).flatten.compact.uniq
        categories = all_categories.select { |c| c.downcase.include?(q.downcase) }.first(3)

        render json: {
          deals: deals.map { |d| { id: d.id, name: d.name, price: d.price, store: d.store, image_url: d.image_url, discount: d.discount } },
          stores: stores,
          categories: categories
        }
      end
    end
  end
end
