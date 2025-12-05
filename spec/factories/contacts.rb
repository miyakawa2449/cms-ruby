FactoryBot.define do
  factory :contact do
    name { "MyString" }
    email { "MyString" }
    subject { "MyString" }
    message { "MyText" }
    ip_address { "" }
    user_agent { "MyText" }
    referrer { "MyString" }
    status { "MyString" }
    assigned_to { nil }
    spam_score { "9.99" }
    is_spam { false }
    replied_at { "2025-12-05 18:25:17" }
    notes { "MyText" }
  end
end
