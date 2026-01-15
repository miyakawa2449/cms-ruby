# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_blob, class: 'ActiveStorage::Blob' do
    key { SecureRandom.uuid }
    filename { 'test_image.jpg' }
    content_type { 'image/jpeg' }
    metadata { { width: 1920, height: 1080 } }
    byte_size { 2_457_600 }
    checksum { Digest::MD5.base64digest('test_checksum') }
    service_name { 'local' }

    trait :png do
      filename { 'test_image.png' }
      content_type { 'image/png' }
    end

    trait :large do
      byte_size { 10_485_760 } # 10MB
    end
  end
end
