# frozen_string_literal: true

module Api
  module V1
    class CouponSubmissionsController < ApplicationController
      def create
        submission = CouponSubmission.new(coupon_submission_params)
        if submission.save
          render json: { message: 'Coupon submitted for review. Thank you!' }, status: :created
        else
          render json: { errors: submission.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def coupon_submission_params
        params.require(:coupon_submission).permit(
          :store, :code, :description, :discount_value, :discount_type, :submitted_by_email
        )
      end
    end
  end
end
