FactoryBot.define do
  factory :site_setting do
    key { "MyString" }
    value { "MyText" }
    description { "MyText" }
    setting_type { "MyString" }
  end
end
