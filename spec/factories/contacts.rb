FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Test User #{n}" }
    sequence(:email) { |n| "test#{n}@example.com" }
    subject { "お問い合わせ" }
    message { "お問い合わせ内容です。" }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0" }
    referrer { "https://example.com" }
    status { "unread" }
    assigned_to_id { nil }
    spam_score { 0.0 }
    is_spam { false }
    replied_at { nil }
    notes { nil }
  end
end
