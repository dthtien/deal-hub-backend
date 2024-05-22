module Api
  module V1
    class MetadataController < ApplicationController
      def show
        service = Deals::Index.new(params, with_order: false)
        service.call

        render json: {
          brands: service.products.brands,
          categories: service.products.categories,
          stores: service.products.stores
        }
      end
    end
  end
end
