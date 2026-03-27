# frozen_string_literal: true

module Admin
  class CouponSubmissionsController < Admin::BaseController
    def index
      @submissions = CouponSubmission.order(created_at: :desc).page(params[:page]).per(30)
      @pending_count = CouponSubmission.pending.count
    end

    def approve
      @submission = CouponSubmission.find(params[:id])
      coupon = Coupon.create!(
        store: @submission.store,
        code: @submission.code,
        description: @submission.description,
        discount_value: @submission.discount_value,
        discount_type: @submission.discount_type || 'percent',
        verified: true,
        active: true
      )
      @submission.update!(status: 'approved')
      redirect_to admin_coupon_submissions_path, notice: "Submission approved and Coupon ##{coupon.id} created."
    end

    def reject
      @submission = CouponSubmission.find(params[:id])
      @submission.update!(status: 'rejected')
      redirect_to admin_coupon_submissions_path, notice: 'Submission rejected.'
    end
  end
end
