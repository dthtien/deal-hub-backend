# frozen_string_literal: true

module Api
  module V1
    class DealSentimentsController < ApplicationController
      POSITIVE_KEYWORDS = %w[great amazing cheap bargain love excellent worth recommended].freeze
      NEGATIVE_KEYWORDS = %w[expensive overpriced waste disappointed broken bad avoid].freeze
      CACHE_TTL = 30.minutes

      def show
        product_id = params[:deal_id]
        cache_key = "deal_sentiment_v1_#{product_id}"

        result = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
          comments = Comment.where(product_id: product_id).active_comments.pluck(:body)
          calculate_sentiment(comments)
        end

        render json: result
      end

      private

      def calculate_sentiment(comments)
        return { positive: 0, negative: 0, neutral: 0, score: 0.0, total: 0 } if comments.empty?

        positive = 0
        negative = 0

        comments.each do |body|
          text = body.to_s.downcase
          pos = POSITIVE_KEYWORDS.count { |kw| text.include?(kw) }
          neg = NEGATIVE_KEYWORDS.count { |kw| text.include?(kw) }
          if pos > neg
            positive += 1
          elsif neg > pos
            negative += 1
          end
        end

        total = comments.size
        neutral = total - positive - negative
        score = total > 0 ? ((positive - negative).to_f / total).round(3) : 0.0

        { positive: positive, negative: negative, neutral: neutral, score: score, total: total }
      end
    end
  end
end
