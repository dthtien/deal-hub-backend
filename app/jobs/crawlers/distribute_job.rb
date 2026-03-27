# frozen_string_literal: true

module Crawlers
  class DistributeJob < ApplicationJob
    def perform
      Rails.logger.info 'Distributing crawl jobs with smart scheduling!'

      jobs = {
        Product::OFFICE_WORKS => Crawlers::OfficeWorksJob,
        Product::JB_HIFI => Crawlers::JbHifiJob,
        Product::GLUE_STORE => Crawlers::GlueStoreJob,
        # Product::NIKE => Crawlers::NikeJob,
        Product::CULTURE_KINGS => Crawlers::CultureKingsJob,
        Product::JD_SPORTS => Crawlers::JdSportsJob,
        Product::MYER => Crawlers::MyerJob,
        Product::THE_GOOD_GUYS => Crawlers::TheGoodGuysJob,
        Product::ASOS => Crawlers::AsosJob,
        Product::THE_ICONIC => Crawlers::TheIconicJob,
        Product::KMART => Crawlers::KmartJob,
        Product::BIG_W => Crawlers::BigWJob,
        Product::BOOKING_COM => Crawlers::BookingComJob,
        Product::GOOD_BUYZ => Crawlers::GoodBuyzJob,
        Product::BEGINNING_BOUTIQUE => Crawlers::BeginningBoutiqueJob,
        Product::UNIVERSAL_STORE => Crawlers::UniversalStoreJob,
        Product::LORNA_JANE => Crawlers::LornaJaneJob
      }

      # Check last update time per store to avoid unnecessary crawls
      store_last_updated = Product.group(:store)
                                  .maximum(:updated_at)

      Product::STORES.each do |store|
        job_class = jobs[store]
        next unless job_class

        last_updated = store_last_updated[store]

        if last_updated.nil?
          # Never crawled - crawl immediately
          Rails.logger.info "Store #{store}: never crawled - scheduling immediately"
          job_class.perform_async
        else
          age_hours = (Time.current - last_updated) / 1.hour

          if age_hours < 1
            # Fresh - skip to reduce server load
            Rails.logger.info "Store #{store}: fresh (#{age_hours.round(1)}h ago) - skipping"
            next
          elsif age_hours <= 3
            # Slightly stale - crawl at low priority
            Rails.logger.info "Store #{store}: stale (#{age_hours.round(1)}h ago) - scheduling low priority"
            job_class.set(queue: :low).perform_async
          else
            # Old data - crawl immediately at normal priority
            Rails.logger.info "Store #{store}: old (#{age_hours.round(1)}h ago) - scheduling immediately"
            job_class.perform_async
          end
        end
      end
    end
  end
end
