# frozen_string_literal: true

module Crawlers
  class DistributeJob < ApplicationJob
    def perform
      Rails.logger.info 'Distributing crawl jobs with adaptive scheduling!'

      jobs = {
        Product::OFFICE_WORKS     => Crawlers::OfficeWorksJob,
        Product::JB_HIFI          => Crawlers::JbHifiJob,
        Product::GLUE_STORE       => Crawlers::GlueStoreJob,
        Product::CULTURE_KINGS    => Crawlers::CultureKingsJob,
        Product::JD_SPORTS        => Crawlers::JdSportsJob,
        Product::MYER             => Crawlers::MyerJob,
        Product::THE_GOOD_GUYS    => Crawlers::TheGoodGuysJob,
        Product::ASOS             => Crawlers::AsosJob,
        Product::THE_ICONIC       => Crawlers::TheIconicJob,
        Product::KMART            => Crawlers::KmartJob,
        Product::BIG_W            => Crawlers::BigWJob,
        Product::BOOKING_COM      => Crawlers::BookingComJob,
        Product::GOOD_BUYZ        => Crawlers::GoodBuyzJob,
        Product::BEGINNING_BOUTIQUE => Crawlers::BeginningBoutiqueJob,
        Product::UNIVERSAL_STORE  => Crawlers::UniversalStoreJob,
        Product::LORNA_JANE       => Crawlers::LornaJaneJob
      }

      store_last_updated = Product.group(:store).maximum(:updated_at)

      Product::STORES.each do |store|
        job_class = jobs[store]
        next unless job_class

        last_updated = store_last_updated[store]
        low_yield = low_yield_store?(store)

        if last_updated.nil?
          Rails.logger.info "Store #{store}: never crawled - scheduling immediately"
          job_class.perform_async
          next
        end

        age_hours = (Time.current - last_updated) / 1.hour

        if low_yield
          # Low yield stores: only crawl once per day (24+ hours)
          if age_hours >= 24
            Rails.logger.info "Store #{store}: low yield, reducing frequency - scheduling once per day"
            job_class.set(queue: :low).perform_async
          else
            Rails.logger.info "Store #{store}: low yield, recently crawled (#{age_hours.round(1)}h ago) - skipping"
          end
          next
        end

        # Normal stores: keep at 5x/day (every ~5h)
        if age_hours < 1
          Rails.logger.info "Store #{store}: fresh (#{age_hours.round(1)}h ago) - skipping"
        elsif age_hours <= 3
          Rails.logger.info "Store #{store}: stale (#{age_hours.round(1)}h ago) - scheduling low priority"
          job_class.set(queue: :low).perform_async
        else
          Rails.logger.info "Store #{store}: old (#{age_hours.round(1)}h ago) - scheduling immediately"
          job_class.perform_async
        end
      end
    end

    private

    # Returns true if the store had 0 new products in the last 3 crawl logs
    def low_yield_store?(store)
      recent_logs = CrawlLog.where(store: store)
                             .order(crawled_at: :desc)
                             .limit(3)
      return false if recent_logs.size < 3

      recent_logs.all? { |log| log.products_new.to_i == 0 }
    end
  end
end
