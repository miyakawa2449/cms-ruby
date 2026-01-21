FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { TestCredentials.admin_password }
    password_confirmation { TestCredentials.admin_password }
  end
end
