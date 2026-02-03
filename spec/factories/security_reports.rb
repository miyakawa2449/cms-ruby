# frozen_string_literal: true

FactoryBot.define do
  factory :security_report do
    report_type { :weekly }
    status { :completed }
    period_start { 1.week.ago }
    period_end { Time.current }
    data { {} }
    generated_at { Time.current }

    trait :weekly do
      report_type { :weekly }
    end

    trait :monthly do
      report_type { :monthly }
    end

    trait :pending do
      status { :pending }
      generated_at { nil }
    end

    trait :generating do
      status { :generating }
      generated_at { nil }
    end

    trait :completed do
      status { :completed }
      generated_at { Time.current }
    end

    trait :failed do
      status { :failed }
      generated_at { nil }
    end

    trait :with_data do
      data do
        {
          "scans" => {
            "total" => 7,
            "brakeman" => 7,
            "bundler_audit" => 7,
            "completed" => 14,
            "failed" => 0
          },
          "vulnerabilities" => {
            "total" => 5,
            "new" => 3,
            "fixed" => 2,
            "by_severity" => {
              "critical" => 1,
              "high" => 2,
              "medium" => 1,
              "low" => 1,
              "info" => 0
            }
          },
          "incidents" => {
            "failed_logins" => 10,
            "blocked_ips" => 5,
            "csrf_errors" => 2,
            "unauthorized_access" => 3
          }
        }
      end
    end
  end
end
