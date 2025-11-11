FactoryBot.define do
  factory :vacation_balance do
    user { nil }
    year { 1 }
    total_days { 1 }
    used_days { 1 }
    created_at { "2025-09-01 14:00:50" }
    updated_at { "2025-09-01 14:00:50" }
  end
end
