module Api
  module V1
    class DealsController < ApplicationController
      def index
        render json: Product.all
      end
    end
  end
end
