module Api
  module V1
    class DealsController < ApplicationController
      def index
        service = Deals::Index.call(params.merge(exclude_count: true))

        render json: {
          products: service.paginate.collection,
          metadata: service.paginate.metadata
        }
      end
    end
  end
end
