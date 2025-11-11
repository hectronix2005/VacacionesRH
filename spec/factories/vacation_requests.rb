FactoryBot.define do
  factory :vacation_request do
    user { nil }
    start_date { "2025-09-01" }
    end_date { "2025-09-01" }
    days_requested { 1 }
    status { 1 }
    reason { "MyText" }
    approved_by { nil }
    approved_at { "2025-09-01 14:04:04" }
    rejected_reason { "MyText" }
  end
end
