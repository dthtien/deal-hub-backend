# frozen_string_literal: true

class AffiliateHealthCheckJob < ApplicationJob
  queue_as :low

  DEAD_CODES = [404, 410].freeze

  def perform
    stores = Product.where(expired: false).distinct.pluck(:store).compact

    stores.each do |store|
      sample = Product.where(store: store, expired: false)
                      .where.not(store_path: [nil, ''])
                      .order('RANDOM()')
                      .limit(10)

      sample.each do |product|
        url = product.store_url
        next if url.blank?

        begin
          uri = URI.parse(url)
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 5) do |http|
            response = http.head(uri.request_uri)
            if DEAD_CODES.include?(response.code.to_i)
              product.update_columns(expired: true)
              Rails.logger.info("[AffiliateHealthCheck] Marked expired: product #{product.id} (#{store}) — HTTP #{response.code}")
            else
              Rails.logger.info("[AffiliateHealthCheck] OK: product #{product.id} (#{store}) — HTTP #{response.code}")
            end
          end
        rescue => e
          Rails.logger.warn("[AffiliateHealthCheck] Error checking product #{product.id}: #{e.message}")
        end
      end
    end
  end
end
