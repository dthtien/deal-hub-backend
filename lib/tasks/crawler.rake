namespace :crawler do
  desc 'Crawl all stores!'
  task crawl_all: :environment do
    Rails.logger.info 'Crawling all stores!'
    puts 'Crawling all stores!'

    jobs = {
      Product::OFFICE_WORKS => Crawlers::OfficeWorksJob,
      Product::JB_HIFI => Crawlers::JbHifiJob
    }

    Product::STORES.each do |store|
      jobs[store].perform_async
    end
  end
end
