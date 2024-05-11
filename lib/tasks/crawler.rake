namespace :crawler do
  desc 'Crawl all stores!'
  task crawl_all: :environment do
    jobs = {
      Product::OFFICE_WORKS => Crawlers::OfficeWorksJob
    }

    Product::STORES.each do |store|
      jobs[store].perform_async
    end
  end
end
