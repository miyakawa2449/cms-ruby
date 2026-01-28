FactoryBot.define do
  factory :admin_path_history do
    association :admin_user
    old_path { "old-admin-path" }
    sequence(:new_path) { |n| "new-admin-path-#{n}" }
    change_type { "manual" }
    ip_address { "127.0.0.1" }
    reason { "テスト変更" }
    notified_at { Time.current }
  end
end
