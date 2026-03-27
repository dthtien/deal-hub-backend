FactoryBot.define do
  factory :notification_log do
    notification_type { 'price_alert_digest' }
    sequence(:recipient) { |n| "user#{n}@example.com" }
    subject { 'Your price alert digest' }
    status { 'sent' }
  end
end
