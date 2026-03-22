module Api
  module V1
    class PushSubscriptionsController < ApplicationController
      def create
        sub = JSON.parse(params[:subscription])
        PushSubscription.find_or_create_by!(
          endpoint: sub['endpoint']
        ) do |s|
          s.p256dh = sub.dig('keys', 'p256dh')
          s.auth   = sub.dig('keys', 'auth')
        end
        render json: { status: 'ok' }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        sub = JSON.parse(params[:subscription])
        PushSubscription.find_by(endpoint: sub['endpoint'])&.destroy
        render json: { status: 'ok' }
      end
    end
  end
end
