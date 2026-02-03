# frozen_string_literal: true

FactoryBot.define do
  factory :media_metadata do
    association :blob, factory: :active_storage_blob_with_file
    alt_text { 'テスト画像' }
    width { 1920 }
    height { 1080 }
    mime_type { 'image/jpeg' }
    file_size { 2_457_600 }
    variants { {} }
    usage_count { 0 }

    trait :used do
      usage_count { 3 }
    end

    trait :with_variants do
      variants do
        {
          'thumb' => 'http://example.com/thumb.jpg',
          'medium' => 'http://example.com/medium.jpg',
          'large' => 'http://example.com/large.jpg'
        }
      end
    end
  end
end
