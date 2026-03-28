# frozen_string_literal: true

module Api
  module V1
    class CollectionsController < ApplicationController
      def index
        collections = Collection.active.includes(:products).order(:name)
        render json: {
          collections: collections.map { |c|
            c.as_json.merge(product_count: c.product_count)
          }
        }
      end

      def show
        collection = Collection.active.find_by!(slug: params[:slug])
        page = (params[:page] || 1).to_i
        per_page = 20
        products = collection.products.order('collection_items.position ASC NULLS LAST, products.created_at DESC')
                             .offset((page - 1) * per_page).limit(per_page)
        total = collection.products.count

        render json: {
          collection: collection.as_json.merge(product_count: total),
          products: products.as_json,
          metadata: {
            page: page,
            total_count: total,
            total_pages: (total / per_page.to_f).ceil,
            show_next_page: page < (total / per_page.to_f).ceil
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
