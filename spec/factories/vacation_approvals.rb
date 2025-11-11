FactoryBot.define do
  factory :vacation_approval do
    vacation_request { nil }
    user { nil }
    role { "MyString" }
    approved_at { "2025-09-01 14:36:56" }
    comments { "MyText" }
  end
end
