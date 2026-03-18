# frozen_string_literal: true

FactoryBot.define do
  factory :click_tracking do
    association :product
    store { product.store }
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0 (Test)' }
    referrer { 'https://dealhub.com' }
    clicked_at { Time.current }
  end
end
