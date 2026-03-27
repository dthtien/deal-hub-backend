FactoryBot.define do
  factory :category_alert do
    sequence(:email) { |n| "user#{n}@example.com" }
    category { "Women's Fashion" }
    active { true }
  end
end
