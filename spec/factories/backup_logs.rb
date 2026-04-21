# frozen_string_literal: true

FactoryBot.define do
  factory :backup_log do
    backup_type { :daily }
    status { :in_progress }
    started_at { Time.current }
    completed_at { nil }
    file_size { nil }
    error_message { nil }
    s3_keys { [] }
  end
end
