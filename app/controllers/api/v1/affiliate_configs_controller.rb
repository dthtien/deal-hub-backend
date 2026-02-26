# frozen_string_literal: true

module Api
  module V1
    class AffiliateConfigsController < ApplicationController
      before_action :authenticate_admin!, except: :index
      before_action :set_config, only: %i[update destroy]

      # GET /api/v1/affiliate_configs
      # Public — FE fetches this on load for affiliate URL building
      def index
        render json: {
          affiliate_configs: AffiliateConfig.as_map,
          all: AffiliateConfig.order(:store).map(&method(:serialize))
        }
      end

      # POST /api/v1/affiliate_configs
      def create
        config = AffiliateConfig.new(config_params)
        if config.save
          render json: { affiliate_config: serialize(config) }, status: :created
        else
          render json: { errors: config.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/affiliate_configs/:id
      def update
        if @config.update(config_params)
          render json: { affiliate_config: serialize(@config) }
        else
          render json: { errors: @config.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/affiliate_configs/:id
      def destroy
        @config.destroy
        render json: { message: 'Deleted' }
      end

      private

      def set_config
        @config = AffiliateConfig.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def config_params
        params.require(:affiliate_config).permit(:store, :param_name, :param_value, :active)
      end

      def serialize(config)
        config.as_json(only: %i[id store param_name param_value active created_at updated_at])
      end

      def authenticate_admin!
        token = request.headers['X-Admin-Token']
        return if token == ENV.fetch('ADMIN_API_TOKEN', 'changeme')

        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
