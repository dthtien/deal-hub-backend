module Api
  module V1
    class TrendingSearchesController < ApplicationController
      def index
        searches = SearchQuery.trending(limit: 10).pluck(:query, :count)
        render json: searches.map { |q, c| { query: q, count: c } }
      end
    end
  end
end
