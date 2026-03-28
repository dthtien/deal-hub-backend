# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CrawlerHealthController < ActionController::Base
        before_action :authenticate_admin!

        def index
          stores = Product::STORES

          # Get last crawled at per store from CrawlLog
          last_logs = CrawlLog
            .select('DISTINCT ON (store) store, crawled_at, products_found')
            .order('store, crawled_at DESC')
            .index_by(&:store)

          # Get product counts per store
          counts = Product.where(expired: false)
                          .group(:store)
                          .count

          now = Time.current

          health = stores.map do |store|
            log = last_logs[store]
            last_crawled_at = log&.crawled_at

            status = if last_crawled_at.nil?
                       'dead'
                     elsif now - last_crawled_at < 6.hours
                       'healthy'
                     elsif now - last_crawled_at < 24.hours
                       'stale'
                     else
                       'dead'
                     end

            {
              store: store,
              last_crawled_at: last_crawled_at&.iso8601,
              products_count: counts[store].to_i,
              status: status
            }
          end

          render json: { health: health }
        end

        private

        def authenticate_admin!
          authenticate_or_request_with_http_basic('Admin') do |username, password|
            username == ENV.fetch('ADMIN_USERNAME', 'admin') &&
              ActiveSupport::SecurityUtils.secure_compare(
                password,
                ENV.fetch('ADMIN_PASSWORD', 'changeme')
              )
          end
        end
      end
    end
  end
end
