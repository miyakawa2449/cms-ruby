FactoryBot.define do
  factory :my_story_section do
    section_type do
      available = MyStorySection::SECTION_TYPES - MyStorySection.pluck(:section_type)
      available.first || MyStorySection::SECTION_TYPES.first
    end
    sequence(:title) { |n| "My Story Section #{n}" }
    subtitle { "Subtitle" }
    content { "Section content" }
    position { 0 }
    is_active { true }
    additional_data { {} }
  end
end
