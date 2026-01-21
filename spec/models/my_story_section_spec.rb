require 'rails_helper'

RSpec.describe MyStorySection, type: :model do
  before do
    MyStorySection.delete_all
  end

  it 'returns section type labels and helpers' do
    section = create(:my_story_section, section_type: 'hero', title: 'Hero')

    expect(section.section_type_label).to eq('ヒーローセクション')
    expect(section.chapter_section?).to eq(false)
    expect(section.hero_section?).to eq(true)
  end

  it 'loads and syncs chapter fields' do
    section = create(
      :my_story_section,
      section_type: 'chapter_1',
      additional_data: { 'skills' => ['Ruby'], 'achievements' => ['Win'], 'quote' => 'Quote' }
    )

    reloaded = MyStorySection.find(section.id)
    expect(reloaded.skills).to include('Ruby')
    expect(reloaded.achievements).to include('Win')
    expect(reloaded.quote).to eq('Quote')

    reloaded.skills = "Go\nRust"
    reloaded.achievements = "A\nB"
    reloaded.quote = 'New'
    reloaded.save!

    reloaded.reload
    expect(reloaded.additional_data['skills']).to include('Go')
    expect(reloaded.additional_data['achievements']).to include('A')
    expect(reloaded.additional_data['quote']).to eq('New')
  end

  it 'assigns default position using next_position' do
    create(:my_story_section, section_type: 'hero', position: 0)
    create(:my_story_section, section_type: 'timeline', position: 1)

    section = create(:my_story_section, section_type: 'chapter_1', position: nil)

    expect(section.position).to eq(2)
  end
end
