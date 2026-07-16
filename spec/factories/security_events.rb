# frozen_string_literal: true

FactoryBot.define do
  factory :security_event do
    event_type { "login_failure" }
    email { "attacker@example.com" }
    ip { "203.0.113.10" }
    path { "/admin/sign_in" }
    user_agent { "TestAgent" }
    metadata { {} }
    occurred_at { Time.current }
  end
end
