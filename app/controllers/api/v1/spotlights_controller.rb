# frozen_string_literal: true

module Api
  module V1
    class SpotlightsController < ApplicationController
      def index
        spotlights = DealSpotlight.active_now.ordered.includes(:product)
        render json: { spotlights: spotlights.map(&:as_json) }
      end
    end
  end
end
