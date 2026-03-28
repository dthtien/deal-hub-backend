# frozen_string_literal: true

module Api
  module V1
    class ComparisonSessionsController < ApplicationController
      def create
        session_id  = params[:session_id].to_s.strip
        product_ids = Array(params[:product_ids]).map(&:to_i).uniq

        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?
        return render json: { error: 'product_ids required' }, status: :unprocessable_entity if product_ids.empty?

        record = ComparisonSession.create!(session_id: session_id, product_ids: product_ids)
        render json: { comparison_session: record }, status: :created
      end

      def index
        session_id = params[:session_id].to_s.strip
        return render json: { error: 'session_id required' }, status: :unprocessable_entity if session_id.blank?

        sessions = ComparisonSession.where(session_id: session_id).recent.limit(5)
        render json: { comparison_sessions: sessions }
      end
    end
  end
end
