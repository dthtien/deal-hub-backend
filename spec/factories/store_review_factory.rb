FactoryBot.define do
  factory :store_review do
    store_name { 'Kmart' }
    rating { 4 }
    comment { 'Great deals!' }
    sequence(:session_id) { |n| "session-#{n}" }
  end
end
