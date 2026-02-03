# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability do
    security_scan
    severity { :medium }
    title { "Test Vulnerability" }
    description { "This is a test vulnerability description" }
    file_path { "app/models/user.rb" }
    line_number { 42 }
    gem_name { nil }
    gem_version { nil }
    cve_id { nil }
    patched_versions { nil }
    fixed { false }
    fixed_at { nil }

    trait :critical do
      severity { :critical }
      title { "Critical Vulnerability" }
    end

    trait :high do
      severity { :high }
      title { "High Severity Vulnerability" }
    end

    trait :medium do
      severity { :medium }
      title { "Medium Severity Vulnerability" }
    end

    trait :low do
      severity { :low }
      title { "Low Severity Vulnerability" }
    end

    trait :info do
      severity { :info }
      title { "Informational Finding" }
    end

    trait :fixed do
      fixed { true }
      fixed_at { Time.current }
    end

    trait :from_bundler_audit do
      gem_name { "vulnerable_gem" }
      gem_version { "1.0.0" }
      cve_id { "CVE-2024-12345" }
      patched_versions { ">= 1.0.1" }
      file_path { nil }
      line_number { nil }
    end
  end
end
