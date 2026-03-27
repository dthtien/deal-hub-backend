# frozen_string_literal: true

module Api
  module V1
    class VotesController < ApplicationController
      before_action :set_product

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
