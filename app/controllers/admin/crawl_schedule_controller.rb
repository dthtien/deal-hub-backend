# frozen_string_literal: true

module Admin
  class CrawlScheduleController < BaseController
    # Approximate crawl frequency per store in hours
    CRAWL_FREQUENCIES = {
      'Office Works'      => 6,
      'JB Hi-Fi'         => 4,
      'Glue Store'        => 12,
      'Nike'              => 24,
      'Culture Kings'     => 12,
      'JD Sports'         => 12,
      'Myer'              => 8,
      'The Good Guys'     => 4,
      'ASOS'              => 6,
      'The Iconic'        => 6,
      'Kmart'             => 8,
      'Big W'             => 8,
      'Target AU'         => 8,
      'Booking.com'       => 24,
      'Good Buyz'         => 6,
      'Beginning Boutique' => 12,
      'Universal Store'   => 12,
      'Lorna Jane'        => 12
    }.freeze

    def index
      stores = Product::STORES

      @schedule = stores.map do |store|
        last_log = CrawlLog.where(store: store).order(crawled_at: :desc).first
        freq_hours = CRAWL_FREQUENCIES[store] || 12
        last_crawled = last_log&.crawled_at
        next_scheduled = last_crawled ? last_crawled + freq_hours.hours : nil
        expected_products = last_log&.products_found

        {
          store: store,
          last_crawled: last_crawled,
          next_scheduled: next_scheduled,
          freq_hours: freq_hours,
          expected_products: expected_products,
          overdue: next_scheduled && next_scheduled < Time.current
        }
      end

      @schedule.sort_by! { |s| s[:next_scheduled] || Time.current + 999.hours }
    end
  end
end
