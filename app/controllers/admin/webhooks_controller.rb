# frozen_string_literal: true

module Admin
  class WebhooksController < BaseController
    def index
      @webhooks = Webhook.order(created_at: :desc)
      render json: @webhooks
    end

    def create
      @webhook = Webhook.new(webhook_params)
      @webhook.secret = SecureRandom.hex(32) if @webhook.secret.blank?
      if @webhook.save
        render json: @webhook, status: :created
      else
        render json: { errors: @webhook.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @webhook = Webhook.find(params[:id])
      @webhook.destroy
      render json: { ok: true }
    end

    private

    def webhook_params
      params.require(:webhook).permit(:url, :secret, :active, events: [])
    end
  end
end
