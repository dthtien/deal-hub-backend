# frozen_string_literal: true

module Api
  module V1
    class ErrorsController < ApplicationController
      def create
        message    = params[:message].to_s.truncate(1000)
        stack      = params[:stack].to_s.truncate(3000)
        url        = params[:url].to_s.truncate(500)
        user_agent = params[:user_agent].to_s.truncate(300)

        Rails.logger.error(
          "[FrontendError] #{message} | url=#{url} | ua=#{user_agent}\n#{stack}"
        )

        render json: { ok: true }, status: :ok
      end
    end
  end
end
