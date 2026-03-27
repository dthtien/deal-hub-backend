module Crawlers
  class DistributeJob < ApplicationJob
    def perform
      Rails.logger.info 'Distributing jobs!'

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
        Product::UNIVERSAL_STORE => Crawlers::UniversalStoreJob
      }

      Product::STORES.each do |store|
        jobs[store]&.perform_async
      end
    end
  end
end
