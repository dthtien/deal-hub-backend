# frozen_string_literal: true

module Admin
  class CrawlLogsController < BaseController
    def index
      @crawl_logs = CrawlLog.order(crawled_at: :desc).page(params[:page]).per(50)
    end
  end
end
