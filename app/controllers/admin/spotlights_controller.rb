# frozen_string_literal: true

module Admin
  class SpotlightsController < BaseController
    before_action :set_spotlight, only: %i[show update destroy]

    def index
      @spotlights = DealSpotlight.includes(:product).ordered
      render json: { spotlights: @spotlights.map(&:as_json) }
    end

    def show
      render json: @spotlight.as_json
    end

    def create
      spotlight = DealSpotlight.new(spotlight_params)
      if spotlight.save
        render json: spotlight.as_json, status: :created
      else
        render json: { errors: spotlight.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @spotlight.update(spotlight_params)
        render json: @spotlight.as_json
      else
        render json: { errors: @spotlight.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @spotlight.destroy
      head :no_content
    end

    private

    def set_spotlight
      @spotlight = DealSpotlight.find(params[:id])
    end

    def spotlight_params
      params.require(:deal_spotlight).permit(
        :product_id, :title, :description, :featured_until, :position, :active
      )
    end
  end
end
