# frozen_string_literal: true

module Admin
  class ApiKeysController < BaseController
    def index
      @api_keys = ApiKey.order(created_at: :desc)
    end

    def create
      @api_key = ApiKey.new(name: params[:name].to_s.strip)
      if @api_key.save
        render json: { id: @api_key.id, key: @api_key.key, name: @api_key.name, active: @api_key.active }, status: :created
      else
        render json: { errors: @api_key.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @api_key = ApiKey.find(params[:id])
      @api_key.update!(active: false)
      render json: { ok: true }
    end
  end
end
