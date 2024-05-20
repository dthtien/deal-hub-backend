module Api
  module V1
    class MetadataController < ApplicationController
      def show
        render json: {
          brands: Product.brands,
          categories: Product.categories,
          stores: Product::STORES
        }
      end
    end
  end
end
