# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      def signup
        user = User.new(signup_params)
        if user.save
          token = JwtService.encode(user_id: user.id)
          render json: { token:, user: user_json(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email]&.downcase)
        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id)
          render json: { token:, user: user_json(user) }
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def me
        authenticate_user!
        return unless current_user

        render json: { user: user_json(current_user) }
      end

      private

      def signup_params
        params.permit(:email, :password, :first_name, :last_name)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name
        }
      end
    end
  end
end
