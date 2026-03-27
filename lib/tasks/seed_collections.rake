# frozen_string_literal: true

namespace :db do
  desc 'Seed collections without resetting data'
  task seed_collections: :environment do
    load Rails.root.join('db', 'seeds.rb')
    puts 'Collections seeded successfully'
  end
end
