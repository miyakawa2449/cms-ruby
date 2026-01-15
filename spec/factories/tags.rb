FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag#{n}" }
    sequence(:slug) { |n| "tag-#{n}" }
    article_count { 0 }
  end
end
