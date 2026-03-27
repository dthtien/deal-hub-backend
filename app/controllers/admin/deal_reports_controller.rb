# frozen_string_literal: true

module Admin
  class DealReportsController < BaseController
    def index
      reports = DealReport.includes(:product)
                          .order(created_at: :desc)
                          .page(params[:page] || 1).per(25)

      render json: {
        reports: reports.map { |r|
          {
            id: r.id,
            reason: r.reason,
            session_id: r.session_id,
            created_at: r.created_at,
            product: r.product ? { id: r.product.id, name: r.product.name, store: r.product.store } : nil,
            report_count: r.product&.deal_reports&.count || 0
          }
        },
        total: reports.total_count,
        page: reports.current_page,
        total_pages: reports.total_pages
      }
    end
  end
end
