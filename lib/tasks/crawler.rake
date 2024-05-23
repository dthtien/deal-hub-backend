namespace :crawler do
  desc 'Crawl all stores!'
  task crawl_all: :environment do
    Rails.logger.info 'Crawling all stores!'

    jobs = {
      Product::OFFICE_WORKS => Crawlers::OfficeWorksJob,
      Product::JB_HIFI => Crawlers::JbHifiJob,
      Product::GLUE_STORE => Crawlers::GlueStoreJob,
      Product::NIKE => Crawlers::NikeJob
    }

    Product::STORES.each do |store|
      jobs[store].perform_async
    end
  end
end
