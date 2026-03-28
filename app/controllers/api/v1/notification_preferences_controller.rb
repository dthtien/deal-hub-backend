# frozen_string_literal: true

module Api
  module V1
    class NotificationPreferencesController < ApplicationController
      def show
        session_id = params[:session_id].to_s.strip
        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?

        pref = UserPreference.find_by(session_id: session_id)
        prefs = pref ? (pref.preferences&.dig('notifications') || {}) : {}

        render json: { session_id: session_id, preferences: prefs }
      end

      def update
        session_id = params[:session_id].to_s.strip
        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?

        pref = UserPreference.find_or_initialize_by(session_id: session_id)
        existing = pref.preferences || {}

        notification_data = {
          email_enabled:  params[:email_enabled],
          push_enabled:   params[:push_enabled],
          frequency:      params[:frequency],
          categories:     Array(params[:categories]),
          max_price:      params[:max_price]
        }.compact

        pref.preferences = existing.merge('notifications' => notification_data)

        if pref.save
          render json: { session_id: session_id, preferences: notification_data }
        else
          render json: { error: pref.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end
    end
  end
end
