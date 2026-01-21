FactoryBot.define do
  factory :section_content do
    association :section
    content { { "message" => "Sample content" } }
    version { 1 }
    is_active { false }
  end
end
