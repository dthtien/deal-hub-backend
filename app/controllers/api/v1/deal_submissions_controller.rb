# frozen_string_literal: true

module Api
  module V1
    class DealSubmissionsController < ApplicationController
      def create
        submission = DealSubmission.new(submission_params)
        if submission.save
          render json: { message: 'Deal submitted! We\'ll review it shortly.' }, status: :created
        else
          render json: { error: submission.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      private

      def submission_params
        params.require(:deal_submission).permit(:title, :url, :price, :old_price, :store, :description, :image_url, :submitted_by_email)
      end
    end
  end
end
