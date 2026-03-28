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

      # Open rate by type
      @open_rate_by_type = NotificationLog
        .group(:notification_type)
        .select(
          :notification_type,
          'COUNT(*) AS sent_count',
          'COUNT(opened_at) AS opened_count'
        )
        .map { |r| {
          type: r.notification_type,
          sent: r.sent_count.to_i,
          opened: r.opened_count.to_i,
          rate: r.sent_count.to_i > 0 ? (r.opened_count.to_f / r.sent_count * 100).round(1) : 0.0
        }}
        .sort_by { |r| -r[:rate] }

      # Open rate by day - last 7 days
      @open_rate_by_day = (6.downto(0)).map do |days_ago|
        date = days_ago.days.ago.to_date
        sent = NotificationLog.where(created_at: date.beginning_of_day..date.end_of_day).count
        opened = NotificationLog.where(created_at: date.beginning_of_day..date.end_of_day).where.not(opened_at: nil).count
        {
          date: date.strftime('%d %b'),
          sent: sent,
          opened: opened,
          rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0.0
        }
      end

      respond_to do |format|
        format.html
        format.json { render json: { logs: @logs, metadata: @meta, open_rate_by_type: @open_rate_by_type, open_rate_by_day: @open_rate_by_day } }
      end
    end
  end
end
