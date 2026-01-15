FactoryBot.define do
  factory :ai_usage_stat do
    date { Date.current }
    ai_model { 'anthropic.claude-3-haiku-20240307-v1:0' }
    total_requests { 10 }
    total_tokens { 15000 }
    total_cost { 0.05 }
    breakdown { { 'summary' => { 'requests' => 5, 'tokens' => 8000 }, 'tags' => { 'requests' => 5, 'tokens' => 7000 } } }

    trait :sonnet do
      ai_model { 'anthropic.claude-3-5-sonnet-20241022-v2:0' }
      total_cost { 0.50 }
    end

    trait :haiku do
      ai_model { 'anthropic.claude-3-haiku-20240307-v1:0' }
      total_cost { 0.05 }
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :last_week do
      date { 1.week.ago.to_date }
    end
  end
end
