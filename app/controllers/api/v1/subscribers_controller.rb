# frozen_string_literal: true

module Api
  module V1
    class SubscribersController < ApplicationController
      def create
        subscriber = Subscriber.find_or_initialize_by(email: subscriber_params[:email].downcase)

        if subscriber.new_record?
          subscriber.assign_attributes(preferences: subscriber_params[:preferences] || {})
          subscriber.save!
          render json: { message: 'Subscribed! Check your inbox for a confirmation.' }, status: :created
        elsif subscriber.status == 'unsubscribed'
          subscriber.update!(status: 'active', preferences: subscriber_params[:preferences] || subscriber.preferences)
          render json: { message: 'Welcome back! You have been re-subscribed.' }, status: :ok
        else
          render json: { message: 'Already subscribed!' }, status: :ok
        end
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      def update_preferences
        subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
        return render json: { error: 'Invalid or expired token.' }, status: :not_found unless subscriber

        allowed_prefs = %w[new_arrivals price_drops weekly_digest daily_alerts]
        prefs = preference_params.to_h.select { |k, _| allowed_prefs.include?(k) }

        current_prefs = subscriber.preferences || {}
        subscriber.update!(preferences: current_prefs.merge(prefs))
        render json: { subscriber: { email: subscriber.email, preferences: subscriber.preferences } }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      def unsubscribe
        subscriber = Subscriber.find_by(unsubscribe_token: params[:token])
        if subscriber
          subscriber.unsubscribe!
          render json: { message: 'You have been unsubscribed successfully.' }
        else
          render json: { error: 'Invalid or expired unsubscribe link.' }, status: :not_found
        end
      end

      def index
        render json: {
          total: Subscriber.active.count,
          subscribers: Subscriber.active.order(created_at: :desc).limit(100).pluck(:email, :created_at)
        }
      end

      private

      def subscriber_params
        params.require(:subscriber).permit(:email, preferences: {})
      end

      def preference_params
        params.require(:preferences).permit(:new_arrivals, :price_drops, :weekly_digest, :daily_alerts)
      end
    end
  end
end
