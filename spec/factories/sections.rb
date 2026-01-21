FactoryBot.define do
  factory :section do
    sequence(:name) { |n| "section-#{n}" }
    sequence(:display_name) { |n| "Section #{n}" }
    is_visible { true }
    position { 0 }
  end
end
