# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authenticatable
  include RequestLogger
  include GeoIp
  include Cacheable

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render json: { error: 'Not found' }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  if Rails.env.production?
    rescue_from StandardError do |e|
      Rails.logger.error(
        "[AppError] #{e.class}: #{e.message} | #{request.method} #{request.path} | #{e.backtrace&.first(5)&.join(' | ')}"
      )
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end
end
