FactoryBot.define do
  factory :slack_notification do
    notification_type { "MyString" }
    reference_id { "" }
    reference_type { "MyString" }
    webhook_url { "MyString" }
    channel { "MyString" }
    payload { "MyText" }
    status { "MyString" }
    error_message { "MyText" }
    retry_count { 1 }
    sent_at { "2025-12-05 18:40:22" }
  end
end
