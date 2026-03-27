# frozen_string_literal: true

module Api
  module V1
    class StoreReviewsController < ApplicationController
      PER_PAGE = 10

      def index
        store_name = URI.decode_www_form_component(params[:store_name].to_s)
        page       = [(params[:page] || 1).to_i, 1].max
        offset     = (page - 1) * PER_PAGE

        reviews = StoreReview.for_store(store_name)
                             .order(created_at: :desc)
                             .limit(PER_PAGE)
                             .offset(offset)
        total = StoreReview.for_store(store_name).count

        render json: {
          reviews:      reviews.map { |r| review_json(r) },
          avg_rating:   StoreReview.avg_rating_for(store_name).to_f,
          review_count: total,
          metadata: {
            page:        page,
            total_count: total,
            total_pages: (total.to_f / PER_PAGE).ceil
          }
        }
      end

      def create
        store_name = URI.decode_www_form_component(params[:store_name].to_s)
        session_id = params[:session_id].to_s.strip

        if session_id.blank?
          return render json: { error: 'session_id is required' }, status: :unprocessable_entity
        end

        review = StoreReview.new(
          store_name: store_name,
          rating:     params[:rating].to_i,
          comment:    params[:comment].to_s.strip.first(1000),
          session_id: session_id
        )

        if review.save
          render json: { message: 'Review submitted', review: review_json(review) }, status: :created
        else
          render json: { error: review.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      private

      def review_json(r)
        {
          id:         r.id,
          rating:     r.rating,
          comment:    r.comment,
          created_at: r.created_at
        }
      end
    end
  end
end
