FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    description { 'カテゴリの説明文' }
    sequence(:position) { |n| n }
  end
end
