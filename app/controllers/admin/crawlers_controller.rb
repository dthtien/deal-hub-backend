# frozen_string_literal: true

module Admin
  class CrawlersController < Admin::BaseController
    def index
      @crawler_stats = Product::STORES.map do |store|
        products = Product.where(store: store)
        last_product = products.order(created_at: :desc).first
        {
          store: store,
          deal_count: products.where(expired: false).count,
          last_crawled_at: last_product&.created_at,
          status: crawl_status(last_product&.created_at)
        }
      end
    end

    private

    def crawl_status(last_crawled_at)
      return :red if last_crawled_at.nil?

      hours_ago = (Time.current - last_crawled_at) / 1.hour
      if hours_ago < 6
        :green
      elsif hours_ago < 24
        :orange
      else
        :red
      end
    end
  end
end
