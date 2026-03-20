# frozen_string_literal: true

module Api
  module V1
    class DealAnalysesController < ApplicationController
      def show
        product = Product.find(params[:deal_id])

        analysis = AiAnalysisService.call(product)

        if analysis
          render json: {
            recommendation: analysis.recommendation,
            confidence: analysis.confidence,
            reasoning: analysis.reasoning,
            stats: {
              lowest_90d: analysis.lowest_90d,
              avg_90d: analysis.avg_90d,
              highest_90d: analysis.highest_90d,
              price_drop_count: analysis.price_drop_count,
              is_lowest_ever: analysis.is_lowest_ever
            },
            analysed_at: analysis.analysed_at
          }
        else
          render json: { error: 'Analysis unavailable' }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end
    end
  end
end
