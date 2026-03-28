# frozen_string_literal: true

require 'net/http'
require 'uri'

class AffiliateValidatorJob < ApplicationJob
  queue_as :low

  DEAD_CODES = [404, 410].freeze
  SAMPLE_SIZE = 20
  TIMEOUT_SECONDS = 10

  def perform
    Rails.logger.info("[AffiliateValidator] Starting affiliate link validation")
    start_time = Time.current
    checked = 0
    broken = 0

    sample = Product.where(expired: false)
                    .where.not(store_path: [nil, ''])
                    .order('RANDOM()')
                    .limit(SAMPLE_SIZE)

    sample.each do |product|
      url = product.store_url
      next if url.blank?

      checked += 1
      result = check_url(url)

      if result[:broken]
        broken += 1
        flag_product(product, result[:reason])
      else
        Rails.logger.info("[AffiliateValidator] OK: product #{product.id} (#{product.store}) - #{result[:status]}")
      end
    rescue => e
      Rails.logger.warn("[AffiliateValidator] Error checking product #{product.id}: #{e.message}")
    end

    duration = (Time.current - start_time).round(2)
    CrawlLog.create!(
      store: 'affiliate_validator',
      products_found: checked,
      products_new: 0,
      products_updated: broken,
      duration_seconds: duration,
      crawled_at: Time.current
    )
    Rails.logger.info("[AffiliateValidator] Completed - checked: #{checked}, broken: #{broken}, duration: #{duration}s")
  end

  private

  def check_url(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = TIMEOUT_SECONDS
    http.read_timeout = TIMEOUT_SECONDS

    response = http.head(uri.request_uri)
    code = response.code.to_i

    if DEAD_CODES.include?(code)
      { broken: true, reason: 'broken_link', status: code }
    else
      { broken: false, status: code }
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
    { broken: true, reason: 'broken_link', status: "timeout:#{e.class}" }
  end

  def flag_product(product, reason)
    product.update_columns(expired: true)
    DealReport.create!(
      product_id: product.id,
      reason: reason,
      session_id: 'affiliate_validator'
    )
    Rails.logger.info("[AffiliateValidator] Flagged product #{product.id} (#{product.store}) as #{reason}")
  end
end
