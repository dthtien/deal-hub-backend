# frozen_string_literal: true

module Admin
  class DealSubmissionsController < BaseController
    before_action :set_submission, only: %i[show approve reject destroy]

    def index
      @status = params[:status] || 'pending'
      @submissions = DealSubmission.where(status: @status).order(created_at: :desc)
    end

    def show; end

    def approve
      if @submission.update(status: 'approved')
        # Create a real product from the submission
        Product.create!(
          name:             @submission.title,
          store_url:        @submission.url,
          price:            @submission.price || 0,
          old_price:        @submission.old_price,
          store:            @submission.store || 'Community',
          description:      @submission.description,
          store_product_id: "sub_#{@submission.id}",
          expired:          false
        )
        redirect_to admin_deal_submissions_path, notice: "Approved and published as a deal."
      else
        redirect_to admin_deal_submissions_path, alert: "Could not approve."
      end
    end

    def reject
      @submission.update(status: 'rejected')
      redirect_to admin_deal_submissions_path, notice: 'Submission rejected.'
    end

    def destroy
      @submission.destroy
      redirect_to admin_deal_submissions_path, notice: 'Deleted.'
    end

    private

    def set_submission
      @submission = DealSubmission.find(params[:id])
    end
  end
end
