FactoryBot.define do
  factory :vacation_approval_config do
    role { "MyString" }
    required { false }
    order_position { 1 }
    active { false }
    description { "MyText" }
  end
end
