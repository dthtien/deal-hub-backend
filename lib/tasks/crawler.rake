namespace :crawler do
  desc 'Crawl all stores!'
  task crawl_all: :environment do
    Crawlers::DistributeJob.perform_async
  end
end
