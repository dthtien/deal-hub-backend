module Crawlers
  class DistributeJob
    include Sidekiq::Worker

    def perform
      Rails.logger.info 'Distributing jobs!'

      jobs = {
        Product::OFFICE_WORKS => Crawlers::OfficeWorksJob,
        Product::JB_HIFI => Crawlers::JbHifiJob,
        Product::GLUE_STORE => Crawlers::GlueStoreJob,
      }

      Product::STORES.each do |store|
        jobs[store].perform_async
      end
    end
  end
end
