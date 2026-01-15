FactoryBot.define do
  factory :ai_generation do
    association :article
    association :admin_user
    generation_type { 'summary' }
    input_content { 'テスト記事の内容です。' }
    output_data { { summaries: [ '要約1', '要約2' ] } }
    model_used { 'anthropic.claude-3-haiku-20240307-v1:0' }
    tokens_used { 1000 }
    cost { 0.001 }
    status { 'pending' }

    trait :completed do
      status { 'completed' }
    end

    trait :failed do
      status { 'failed' }
      error_message { 'API Error' }
    end

    trait :summary do
      generation_type { 'summary' }
      output_data { { summaries: [ { text: '要約1', length: 80 }, { text: '要約2', length: 80 } ] } }
    end

    trait :tags do
      generation_type { 'tags' }
      output_data { { tags: [ { name: 'Ruby', confidence: 0.95 }, { name: 'Rails', confidence: 0.90 } ] } }
    end

    trait :slug do
      generation_type { 'slug' }
      output_data { { slugs: [ { slug: 'test-slug', seo_score: 95 } ] } }
    end

    trait :seo_meta do
      generation_type { 'seo_meta' }
      output_data { { meta_description: 'テスト説明', og_title: 'OGタイトル' } }
    end

    trait :structure do
      generation_type { 'structure' }
      output_data { { structure: { sections: [] } } }
    end
  end
end
