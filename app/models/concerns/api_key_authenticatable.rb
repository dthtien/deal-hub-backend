# frozen_string_literal: true

module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_api_key!
    key_value = request.headers['X-API-Key']
    unless key_value.present? && ApiKey.authenticate(key_value)
      render json: { error: 'Invalid or missing API key' }, status: :unauthorized
    end
  end
end
