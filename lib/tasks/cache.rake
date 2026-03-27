namespace :cache do
  desc "Clear Deal of the Day and Deal of the Week cache"
  task clear_deals: :environment do
    Rails.cache.delete_matched("deal_of_the_day*")
    Rails.cache.delete_matched("deal_of_the_week*")
    puts "Cleared deal of the day/week cache"
  end

  desc "Clear all app cache"
  task clear_all: :environment do
    Rails.cache.clear
    puts "Cleared all cache"
  end
end
