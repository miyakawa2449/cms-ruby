require 'rails_helper'

RSpec.describe MyStorySectionValidator do
  before do
    MyStorySection.delete_all
  end

  it 'adds errors for unknown section type' do
    section = build(:my_story_section, section_type: 'unknown')
    validator = described_class.new(section)

    expect(validator.validate_all).to eq(false)
    expect(validator.errors[:section_type]).to include('Unknown section type: unknown')
  end

  it 'validates timeline year structure' do
    section = build(:my_story_section, section_type: 'timeline', additional_data: { 'years' => [ { 'year' => '2020' }, 'bad' ] })
    validator = described_class.new(section)

    validator.validate_all

    expect(validator.errors[:timeline_years]).to include('Invalid year data structure')
  end

  it 'validates required fields and positions' do
    section = build(:my_story_section, section_type: 'chapter_1', title: '', content: '', position: -1)
    validator = described_class.new(section)

    validator.validate_all

    expect(validator.errors[:title]).to include('Title cannot be blank')
    expect(validator.errors[:content].join(' ')).to include('Content is required for chapter_1 section')
    expect(validator.errors[:position]).to include('Position cannot be negative')
  end

  it 'rejects overly deep or large JSON data' do
    data = { 'items' => Array.new(101) { |i| i } }
    section = build(:my_story_section, section_type: 'hero', additional_data: data)
    validator = described_class.new(section)

    validator.validate_all

    expect(validator.errors[:additional_data].first).to include('Array too large')
  end

  it 'detects duplicate positions' do
    create(:my_story_section, section_type: 'hero', position: 2)
    section = create(:my_story_section, section_type: 'timeline', position: 2)
    validator = described_class.new(section)

    validator.validate_all

    expect(validator.errors[:position]).to include('Position 2 is already taken by another section')
  end
end
