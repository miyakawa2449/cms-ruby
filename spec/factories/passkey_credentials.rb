FactoryBot.define do
  factory :passkey_credential do
    association :admin_user
    sequence(:external_id) { |n| Base64.urlsafe_encode64("credential-#{n}") }
    public_key { Base64.urlsafe_encode64("dummy-public-key") }
    sequence(:nickname) { |n| "テストデバイス#{n}" }
    sign_count { 0 }
  end
end
