# frozen_string_literal: true

module Admin
  class DealReportsController < BaseController
    PER_PAGE = 25

    def index
      page = (params[:page] || 1).to_i
      offset = (page - 1) * PER_PAGE
      @total = DealReport.count
      @total_pages = (@total.to_f / PER_PAGE).ceil
      @page = page

      @reports = DealReport.includes(:product)
                           .order(created_at: :desc)
                           .limit(PER_PAGE).offset(offset)
    end

    def dismiss
      report = DealReport.find(params[:id])
      report.destroy
      redirect_to admin_deal_reports_path, notice: 'Report dismissed.'
    end

    def expire_deal
      report = DealReport.find(params[:id])
      report.product&.update_column(:expired, true)
      report.destroy
      redirect_to admin_deal_reports_path, notice: 'Deal expired and report dismissed.'
    end
  end
end
