# frozen_string_literal: true

module Api
  module V1
    class DealReportsController < ApplicationController
      VALID_REASONS = %w[expired wrong_price spam broken_link].freeze

      def create
        product = Product.find(params[:deal_id])
        reason  = params[:reason].to_s

        unless VALID_REASONS.include?(reason)
          return render json: { error: "Invalid reason. Valid: #{VALID_REASONS.join(', ')}" }, status: :unprocessable_entity
        end

        report = DealReport.create!(
          product: product,
          reason: reason,
          session_id: params[:session_id]
        )

        report_count = product.deal_reports.count

        render json: { ok: true, report_count: report_count }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Deal not found' }, status: :not_found
      end
    end
  end
end
