FactoryBot.define do
  factory :user do
    document_number { "MyString" }
    phone { "MyString" }
    name { "MyString" }
    country { "MyString" }
    role { 1 }
    password_digest { "MyString" }
    active { false }
    leader_id { 1 }
  end
end
