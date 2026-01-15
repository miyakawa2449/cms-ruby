FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "サンプル記事#{n}" }
    sequence(:slug) { |n| "sample-article-#{n}" }
    content { 'サンプル本文の内容です。' }
    excerpt { 'サンプル抜粋' }
    status { 'draft' }
    association :admin_user

    trait :published do
      status { 'published' }
      published_at { Time.current }
    end

    trait :draft do
      status { 'draft' }
      published_at { nil }
    end

    trait :with_category do
      after(:create) do |article|
        article.categories << create(:category)
      end
    end

    trait :with_categories do
      transient do
        category_count { 2 }
      end
      after(:create) do |article, evaluator|
        evaluator.category_count.times do
          article.categories << create(:category)
        end
      end
    end

    trait :with_tag do
      after(:create) do |article|
        article.tags << create(:tag)
      end
    end

    trait :with_tags do
      transient do
        tag_count { 3 }
      end
      after(:create) do |article, evaluator|
        evaluator.tag_count.times do
          article.tags << create(:tag)
        end
      end
    end
  end
end
