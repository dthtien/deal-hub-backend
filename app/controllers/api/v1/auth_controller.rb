# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, raise: false

      def me
        token = request.headers['Authorization']&.sub('Bearer ', '')
        payload = JwtService.decode(token)

        return render json: { error: 'Unauthorized' }, status: :unauthorized unless payload

        user = User.find_by(id: payload['user_id'])
        return render json: { error: 'User not found' }, status: :not_found unless user

        render json: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          avatar_url: user.avatar_url
        }
      end
    end
  end
end
