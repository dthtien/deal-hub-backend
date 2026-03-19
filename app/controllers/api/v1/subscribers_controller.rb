# frozen_string_literal: true

module Api
  module V1
    class SubscribersController < ApplicationController
      def create
        subscriber = Subscriber.find_or_initialize_by(email: subscriber_params[:email].downcase)

        if subscriber.new_record?
          subscriber.save!
          render json: { message: 'Subscribed successfully!' }, status: :created
        else
          render json: { message: 'Already subscribed!' }, status: :ok
        end
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      def index
        # Admin only - returns subscriber count + list
        render json: {
          total: Subscriber.active.count,
          subscribers: Subscriber.active.order(created_at: :desc).limit(100).pluck(:email, :created_at)
        }
      end

      private

      def subscriber_params
        params.require(:subscriber).permit(:email)
      end
    end
  end
end
