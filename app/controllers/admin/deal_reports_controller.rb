# frozen_string_literal: true

module Admin
  class DealReportsController < BaseController
    PER_PAGE = 25

    def index
      page = (params[:page] || 1).to_i
      offset = (page - 1) * PER_PAGE
      total = DealReport.count

      reports = DealReport.includes(:product)
                          .order(created_at: :desc)
                          .limit(PER_PAGE).offset(offset)

      render json: {
        reports: reports.map { |r|
          report_count = r.product&.deal_reports&.count || 0
          {
            id: r.id,
            reason: r.reason,
            session_id: r.session_id,
            created_at: r.created_at,
            report_count: report_count,
            auto_flagged: report_count >= 3,
            product: r.product ? { id: r.product.id, name: r.product.name, store: r.product.store } : nil
          }
        },
        total: total,
        page: page,
        total_pages: (total.to_f / PER_PAGE).ceil
      }
    end
  end
end
