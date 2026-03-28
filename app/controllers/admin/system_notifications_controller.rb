# frozen_string_literal: true

module Admin
  class SystemNotificationsController < BaseController
    PER_PAGE = 25

    def index
      @page = (params[:page] || 1).to_i
      offset = (@page - 1) * PER_PAGE

      @failed_jobs    = fetch_failed_jobs
      @flagged_products = Product.where(status: 'pending').order(created_at: :desc).limit(20)
      @deal_reports   = DealReport.order(created_at: :desc).limit(20)
      @crawl_warnings = fetch_crawl_warnings

      # Combine all events into one list
      events = []

      @failed_jobs.each do |job|
        events << {
          type: 'failed_job',
          severity: 'error',
          message: "Failed job: #{job[:class]} (#{job[:error]})",
          timestamp: job[:failed_at]
        }
      end

      @flagged_products.each do |p|
        events << {
          type: 'flagged_product',
          severity: 'warning',
          message: "Product flagged for moderation: #{p.name.truncate(60)}",
          timestamp: p.created_at,
          link: admin_product_path(p)
        }
      end

      @deal_reports.each do |r|
        events << {
          type: 'deal_report',
          severity: 'warning',
          message: "New deal report (##{r.id}): #{r.reason.to_s.truncate(80)}",
          timestamp: r.created_at
        }
      end

      @crawl_warnings.each do |w|
        events << {
          type: 'crawl_warning',
          severity: 'info',
          message: w[:message],
          timestamp: w[:timestamp]
        }
      end

      events.sort_by! { |e| e[:timestamp] || Time.at(0) }.reverse!

      @total_events = events.size
      @total_pages  = (@total_events / PER_PAGE.to_f).ceil
      @events = events[offset, PER_PAGE] || []

      respond_to do |format|
        format.html
        format.json { render json: { events: @events, page: @page, total_pages: @total_pages, total: @total_events } }
      end
    end

    private

    def fetch_failed_jobs
      require 'sidekiq/api'
      dead_set = Sidekiq::DeadSet.new
      dead_set.first(50).map do |job|
        {
          class: job.klass,
          error: job['error_message'].to_s.truncate(120),
          failed_at: Time.at(job.score).utc
        }
      end
    rescue StandardError
      []
    end

    def fetch_crawl_warnings
      CrawlLog.where('created_at >= ?', 48.hours.ago)
               .where('products_found < 5 OR products_found IS NULL')
               .order(created_at: :desc)
               .limit(20)
               .map do |log|
        {
          message: "Low-yield crawl: #{log.store} returned #{log.products_found.to_i} products",
          timestamp: log.created_at
        }
      end
    rescue StandardError
      []
    end
  end
end
