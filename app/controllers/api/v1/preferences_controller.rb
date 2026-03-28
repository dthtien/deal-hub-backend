# frozen_string_literal: true

module Api
  module V1
    class PreferencesController < ApplicationController
      def show
        session_id = params[:session_id].to_s.strip
        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?

        pref = UserPreference.find_by(session_id: session_id)
        if pref
          render json: { session_id: pref.session_id, preferences: pref.preferences }
        else
          render json: { session_id: session_id, preferences: {} }
        end
      end

      def create
        session_id = params[:session_id].to_s.strip
        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?

        prefs_data = {
          categories: Array(params[:categories]).map(&:to_s),
          stores:     Array(params[:stores]).map(&:to_s),
          price_min:  params[:price_min].presence&.to_f,
          price_max:  params[:price_max].presence&.to_f,
          brands:     Array(params[:brands]).map(&:to_s)
        }.compact

        pref = UserPreference.find_or_initialize_by(session_id: session_id)
        pref.preferences = prefs_data
        pref.updated_at  = Time.current
        pref.save!

        render json: { session_id: pref.session_id, preferences: pref.preferences }, status: :ok
      end
    end
  end
end
