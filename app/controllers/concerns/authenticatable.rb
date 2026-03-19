# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: []
  end

  def current_user
    @current_user ||= begin
      token = request.headers['Authorization']&.split(' ')&.last
      return nil unless token

      payload = JwtService.decode(token)
      User.find_by(id: payload[:user_id]) if payload
    end
  end

  def authenticate_user!
    render json: { error: 'Unauthorized. Please log in.' }, status: :unauthorized unless current_user
  end

  def logged_in?
    current_user.present?
  end
end
