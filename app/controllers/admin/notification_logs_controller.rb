# frozen_string_literal: true

module Admin
  class NotificationLogsController < BaseController
    PER_PAGE = 50

    def index
      page   = [(params[:page] || 1).to_i, 1].max
      offset = (page - 1) * PER_PAGE

      scope = NotificationLog.recent
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(notification_type: params[:type]) if params[:type].present?

      total = scope.count
      @logs = scope.limit(PER_PAGE).offset(offset)
      @meta = {
        page:        page,
        total_count: total,
        total_pages: (total.to_f / PER_PAGE).ceil
      }

      respond_to do |format|
        format.html
        format.json { render json: { logs: @logs, metadata: @meta } }
      end
    end
  end
end
