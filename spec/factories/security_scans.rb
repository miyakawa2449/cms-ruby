# frozen_string_literal: true

FactoryBot.define do
  factory :security_scan do
    scan_type { :brakeman }
    status { :completed }
    scanned_at { Time.current }
    raw_results { {} }
    error_message { nil }

    trait :brakeman do
      scan_type { :brakeman }
    end

    trait :bundler_audit do
      scan_type { :bundler_audit }
    end

    trait :pending do
      status { :pending }
    end

    trait :running do
      status { :running }
    end

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
      error_message { "Scan failed" }
    end

    trait :with_vulnerabilities do
      after(:create) do |scan|
        create(:vulnerability, security_scan: scan, severity: :high)
        create(:vulnerability, security_scan: scan, severity: :medium)
      end
    end
  end
end
