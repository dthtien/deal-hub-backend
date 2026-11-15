# frozen_string_literal: true

module Api
  module V1
    class VotesController < ApplicationController
      before_action :set_product, except: :index

      MAX_BATCH = 100

      # GET /api/v1/votes?deal_ids=1,2,3
      #
      # Vote counts for many deals in one request, so a page of deal cards
      # makes one call instead of one per card. Unknown ids come back as zero.
      def index
        ids = params[:deal_ids].to_s.split(',')
                               .filter_map { |id| Integer(id.strip, exception: false) }
                               .select(&:positive?).uniq.first(MAX_BATCH)

        counts = Vote.where(product_id: ids).group(:product_id, :value).count
        mine = if session_id.present?
                 Vote.where(product_id: ids, session_id: session_id).pluck(:product_id, :value).to_h
               else
                 {}
               end

        votes = ids.to_h do |id|
          [id.to_s, { upvotes: counts[[id, 1]] || 0, downvotes: counts[[id, -1]] || 0, user_vote: mine[id] }]
        end

        render json: { votes: votes }
      end

      def show
        upvotes   = @product.votes.where(value: 1).count
        downvotes = @product.votes.where(value: -1).count
        user_vote = session_id ? @product.votes.find_by(session_id: session_id)&.value : nil

        render json: { upvotes: upvotes, downvotes: downvotes, user_vote: user_vote }
      end

      def create
        value = params[:value].to_i
        return render json: { error: 'Invalid value' }, status: :unprocessable_entity unless [1, -1].include?(value)
        return render json: { error: 'Missing session' }, status: :unprocessable_entity if session_id.blank?
        return render json: { error: 'Invalid session' }, status: :unprocessable_entity if session_id.length > 100

        vote = @product.votes.find_or_initialize_by(session_id: session_id)

        if vote.value == value && vote.persisted?
          # Toggle off — remove the vote
          vote.destroy
        else
          vote.value = value
          vote.save!
        end

        upvotes   = @product.votes.where(value: 1).count
        downvotes = @product.votes.where(value: -1).count
        user_vote = @product.votes.find_by(session_id: session_id)&.value

        render json: { upvotes: upvotes, downvotes: downvotes, user_vote: user_vote }
      end

      private

      def set_product
        @product = Product.find(params[:deal_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def session_id
        request.headers['X-Session-Id'] || params[:session_id]
      end
    end
  end
end
